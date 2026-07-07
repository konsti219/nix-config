// Main-process half: listens on a unix socket for mute commands from the
// `discord-mute` CLI and queues them for the renderer to apply.
import { IpcMainInvokeEvent } from "electron";
import { existsSync, unlinkSync } from "fs";
import { createServer, Server, Socket } from "net";
import { join } from "path";

type Action = "toggle" | "mute" | "unmute";

const SOCKET_PATH = join(
    process.env.XDG_RUNTIME_DIR || process.env.TMPDIR || "/tmp",
    "discord-mute-bridge.sock"
);

let queue: Action[] = [];
let server: Server | null = null;

function parse(text: string): void {
    for (const raw of text.split(/[\r\n]+/)) {
        const cmd = raw.trim().toLowerCase();
        if (cmd === "toggle" || cmd === "mute" || cmd === "unmute") queue.push(cmd);
    }
}

function start(): void {
    if (server) return;

    // Clear a stale socket from a previous session.
    try {
        if (existsSync(SOCKET_PATH)) unlinkSync(SOCKET_PATH);
    } catch {
        /* ignore */
    }

    server = createServer((sock: Socket) => {
        sock.setEncoding("utf-8");
        let buf = "";
        sock.on("data", d => {
            buf += d;
            const nl = buf.lastIndexOf("\n");
            if (nl !== -1) {
                parse(buf.slice(0, nl));
                buf = buf.slice(nl + 1);
            }
        });
        sock.on("end", () => parse(buf));
        sock.on("error", () => {
            /* ignore per-client errors */
        });
    });

    server.on("error", () => {
        server = null;
    });

    try {
        server.listen(SOCKET_PATH);
    } catch {
        server = null;
    }
}

start();

export function consumeActions(_: IpcMainInvokeEvent): Action[] {
    const out = queue;
    queue = [];
    return out;
}
