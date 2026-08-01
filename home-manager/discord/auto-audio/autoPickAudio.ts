/*
 * Pre-selects the screenshare audio source on Wayland.
 *
 * The xdg-desktop-portal ScreenCast response carries no window title or app
 * name, and Chromium's PipeWire capturer reports an empty title, so the picked
 * window is unidentifiable from Electron alone.
 *
 * Our patched KWin publishes kwin.window.* properties on each screencast node
 * (see kwin-screencast-metadata.patch), including the pid owning the captured
 * window. While the portal dialog is open KWin previews every selectable
 * source, so presence alone means nothing: the previews are consumed by the
 * portal and die with the dialog, while the stream you picked stays alive and
 * is consumed by Chromium.
 *
 * From that pid we match the audio by process, walking children too, because
 * Chromium and Electron play through a dedicated audio process.
 */

import { spawn } from "child_process";
import { readFileSync } from "fs";

import type { Node } from "@vencord/venmic";

const PW_DUMP = "@PW_DUMP@";

const KWIN_PREFIX = "kwin-screencast-";

// How long to keep listening after getSources() returns. Only reached when
// Chromium has not attached to the stream yet; normally we resolve immediately.
const SELECTION_GRACE_MS = 800;

interface PwObject {
    id: number;
    type?: string;
    info?: { props?: Record<string, unknown> } | null;
}

interface Screencast {
    name: string;
    pid?: number;
    resourceClass?: string;
    /** Undefined until something links to the stream. */
    consumer?: string;
    alive: boolean;
}

/** Portal dialog thumbnails, which exist for every selectable source. */
const isPreview = (cast: Screencast) => cast.consumer?.includes("plasma-screencast-") ?? false;

/** Survived the dialog closing, so it is the source that was actually picked. */
const isSelection = (cast: Screencast) => cast.alive && !isPreview(cast);

/** The moment Chromium links itself to that stream — our cue to stop waiting. */
const isAttached = (cast: Screencast) => isSelection(cast) && cast.consumer !== undefined;

function parentPid(pid: number): number | null {
    try {
        const match = /^PPid:\s+(\d+)$/m.exec(readFileSync(`/proc/${pid}/status`, "utf8"));
        return match ? Number(match[1]) : null;
    } catch {
        return null;
    }
}

/** Whether `pid` is `ancestor`, or was spawned by it (at any depth). */
function isSelfOrDescendantOf(pid: number, ancestor: number): boolean {
    let current: number | null = pid;

    // Bounded so a malformed /proc chain can't spin here.
    for (let depth = 0; depth < 16 && current !== null && current > 1; depth++) {
        if (current === ancestor) return true;
        current = parentPid(current);
    }

    return false;
}

/**
 * Accumulates PipeWire registry events. Nodes are remembered even once removed,
 * because whether a screencast survived the dialog closing is exactly what
 * distinguishes the source you picked from the previews of the ones you didn't.
 */
class Registry {
    private nodes = new Map<number, Record<string, unknown>>();
    private links = new Map<number, { from: number; to: number }>();
    private preExisting = new Set<number>();
    private removed = new Set<number>();
    private seenFirstDocument = false;

    private notifyAttached?: () => void;
    readonly attached = new Promise<void>(resolve => {
        this.notifyAttached = resolve;
    });

    apply(document: PwObject[]) {
        for (const object of document) {
            // Removals arrive as { id, info: null } and carry nothing to merge.
            const props = object.info?.props;
            if (!props) {
                this.removed.add(object.id);
                continue;
            }

            if (object.type === "PipeWire:Interface:Node") {
                this.nodes.set(object.id, { ...this.nodes.get(object.id), ...props });

                // pw-dump opens with a snapshot of the whole graph. Anything in
                // it predates the dialog, so it cannot be the stream the portal
                // just started.
                if (!this.seenFirstDocument) this.preExisting.add(object.id);
            } else if (object.type === "PipeWire:Interface:Link") {
                // Keyed by id, not appended: PipeWire re-emits links whenever
                // their state changes, and a growing list would make every
                // later event more expensive than the last.
                this.links.set(object.id, {
                    from: props["link.output.node"] as number,
                    to: props["link.input.node"] as number
                });
            }
        }

        this.seenFirstDocument = true;

        if (this.screencasts().some(isAttached)) this.notifyAttached?.();
    }

    /** Every window screencast that appeared while we were watching. */
    screencasts(): Screencast[] {
        const consumers = new Map<number, string>();

        for (const { from, to } of this.links.values()) {
            const sink = this.nodes.get(to);
            const name = String(sink?.["node.name"] ?? "?");
            const media = String(sink?.["media.name"] ?? "");

            consumers.set(from, media && media !== name ? `${name} (${media})` : name);
        }

        const found: Screencast[] = [];

        for (const [id, props] of this.nodes) {
            if (this.preExisting.has(id)) continue;

            const mediaName = String(props["media.name"] ?? "");
            if (!mediaName.startsWith(KWIN_PREFIX)) continue;

            const pid = Number(props["kwin.window.pid"]);
            const resourceClass = props["kwin.window.resource-class"];

            found.push({
                name: mediaName.slice(KWIN_PREFIX.length) || "(unnamed)",
                pid: Number.isInteger(pid) && pid > 0 ? pid : undefined,
                resourceClass: resourceClass ? String(resourceClass) : undefined,
                consumer: consumers.get(id),
                alive: !this.removed.has(id)
            });
        }

        return found;
    }

    /** The audio a process is playing, counting audio played by its children. */
    audioNodeFor(pid: number): Node | null {
        for (const [id, props] of this.nodes) {
            if (this.removed.has(id)) continue;
            if (props["media.class"] !== "Stream/Output/Audio") continue;

            const audioPid = Number(props["application.process.id"]);
            if (!Number.isInteger(audioPid)) continue;

            // Chromium and Electron play through a dedicated child process, so
            // the window's pid is the stream's ancestor rather than its owner.
            if (!isSelfOrDescendantOf(audioPid, pid)) continue;

            // Prefer the app-wide keys so every stream the app opens is covered,
            // not just the one process we happened to find it through.
            const appName = props["application.name"];
            if (appName) return { "application.name": String(appName) };

            const nodeName = props["node.name"];
            if (nodeName) return { "node.name": String(nodeName) };

            return { "application.process.id": String(audioPid) };
        }

        return null;
    }
}

function resolve(registry: Registry): Node[] | null {
    const seen = registry.screencasts();

    if (!seen.length) {
        console.log("[autoPickAudio] no window screencast appeared while the portal was open");
        return null;
    }

    console.log(
        "[autoPickAudio] saw:",
        seen
            .map(c => {
                const who = c.resourceClass ?? c.name;
                return `${who}${c.pid ? ` pid=${c.pid}` : ""} -> ${c.consumer ?? "(unconsumed)"}${c.alive ? "" : " (gone)"}`;
            })
            .join(", ")
    );

    // Never guess. Pre-selecting the wrong app is worse than pre-selecting
    // nothing, since the dropdown looks decided either way.
    const cast = seen.filter(isSelection).pop();
    if (!cast) {
        console.log("[autoPickAudio] only portal previews seen, cannot tell which source was picked");
        return null;
    }

    const who = cast.resourceClass ?? cast.name;

    if (!cast.pid) {
        console.log(`[autoPickAudio] "${who}" carries no kwin.window.pid (unpatched KWin?)`);
        return null;
    }

    const node = registry.audioNodeFor(cast.pid);
    if (!node) {
        console.log(`[autoPickAudio] "${who}" (pid ${cast.pid}) is not playing any audio`);
        return null;
    }

    console.log(`[autoPickAudio] "${who}" (pid ${cast.pid}) matched`, node);
    return [node];
}

/**
 * Start watching for the portal's preview streams. Call stop() once
 * getSources() has returned to get the audio source to pre-select, if any.
 */
export function watchScreencast() {
    const registry = new Registry();

    // Subscribed rather than polled: a stream can come and go between two
    // samples, but every registry change arrives here as its own document.
    const monitor = spawn(PW_DUMP, ["-m", "-N"], { stdio: ["ignore", "pipe", "ignore"] });

    monitor.on("error", e => console.error("[autoPickAudio] pw-dump --monitor failed", e));

    let buffer = "";
    monitor.stdout.setEncoding("utf8");
    monitor.stdout.on("data", (chunk: string) => {
        buffer += chunk;

        // pw-dump keeps its top-level brackets at column 0, so a lone "]" line
        // closes exactly one document.
        for (;;) {
            const end = buffer.indexOf("\n]\n");
            if (end === -1) break;

            const document = buffer.slice(0, end + 2);
            buffer = buffer.slice(end + 3);

            try {
                registry.apply(JSON.parse(document));
            } catch (e) {
                console.error("[autoPickAudio] could not parse a pw-dump event", e);
            }
        }
    });

    return {
        async stop(): Promise<Node[] | null> {
            // Chromium usually attaches before getSources() returns, in which
            // case this resolves without waiting at all.
            await Promise.race([
                registry.attached,
                new Promise(resolve => setTimeout(resolve, SELECTION_GRACE_MS))
            ]);

            monitor.kill();

            try {
                return resolve(registry);
            } catch (e) {
                console.error("[autoPickAudio] failed to resolve an audio source", e);
                return null;
            }
        }
    };
}
