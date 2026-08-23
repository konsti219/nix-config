// Main-process half: registers voice-mute shortcuts with the desktop portal,
// hands each activation to the renderer, and reflects the muted state in the
// window icon.
import { BrowserWindow, IpcMainInvokeEvent } from "electron";

import { connect, ShortcutsClient } from "./portal";

// Baked in at build time; the muted one is the same artwork with a red
// mic-off badge composited into the bottom-right corner.
const ICON_NORMAL = "@ICON_NORMAL@";
const ICON_MUTED = "@ICON_MUTED@";

type Action = "toggle" | "mute" | "unmute";

// Portal shortcut id -> action. Ids are part of the persisted binding, so
// renaming one drops whatever key the user assigned to it.
const SHORTCUTS = [
    { id: "toggle-mute", description: "Toggle voice mute", action: "toggle" as Action },
    { id: "mute", description: "Mute voice", action: "mute" as Action },
    { id: "unmute", description: "Unmute voice", action: "unmute" as Action }
];

const APP_ID = "vesktop";
const RETRY_DELAY_MS = 2000;
const MAX_RETRY_DELAY_MS = 60_000;

let queue: Action[] = [];
let waiter: ((actions: Action[]) => void) | null = null;
let client: ShortcutsClient | null = null;
let connecting = false;
let retryDelay = RETRY_DELAY_MS;

function log(message: string): void {
    console.log("[DiscordMuteBridge]", message);
}

function flush(): void {
    if (!waiter || queue.length === 0) return;
    const resolve = waiter;
    const actions = queue;
    waiter = null;
    queue = [];
    resolve(actions);
}

function onActivated(id: string): void {
    const shortcut = SHORTCUTS.find(s => s.id === id);
    if (!shortcut) return;
    queue.push(shortcut.action);
    flush();
}

function scheduleRetry(): void {
    const delay = retryDelay;
    retryDelay = Math.min(retryDelay * 2, MAX_RETRY_DELAY_MS);
    setTimeout(start, delay).unref?.();
}

function start(): void {
    if (client || connecting) return;
    connecting = true;

    connect({
        appId: APP_ID,
        shortcuts: SHORTCUTS.map(({ id, description }) => ({ id, description })),
        onActivated,
        onClosed(reason) {
            log(`shortcuts unavailable (${reason}); reconnecting`);
            client = null;
            scheduleRetry();
        },
        log
    })
        .then(connected => {
            client = connected;
            retryDelay = RETRY_DELAY_MS;
        })
        .catch(e => {
            log(`could not register global shortcuts: ${e}`);
            scheduleRetry();
        })
        .finally(() => {
            connecting = false;
        });
}

start();

let iconApplied: string | null = null;

/**
 * Swap the window icon to reflect whether the mic is muted.
 *
 * Goes out as xdg-toplevel-icon-v1, which KWin honours over the desktop-file
 * icon. Plasma's libtaskmanager normally discards it in favour of the launcher
 * icon, so the panel only picks this up with the accompanying
 * plasma-taskmanager-toplevel-icon patch applied.
 *
 * The window is resolved from the calling renderer rather than looked up
 * globally, so the icon lands on the window that actually reported.
 */
export function setMuted(event: IpcMainInvokeEvent, muted: boolean): void {
    const icon = muted ? ICON_MUTED : ICON_NORMAL;
    if (icon === iconApplied) return;

    const win = BrowserWindow.fromWebContents(event.sender);
    if (!win || win.isDestroyed()) return;

    try {
        win.setIcon(icon);
        iconApplied = icon;
    } catch (e) {
        log(`could not update the window icon: ${e}`);
    }
}

// Long poll: resolves as soon as a shortcut fires, so there is no polling
// interval to trade off against latency. Only one waiter is meaningful (the
// renderer runs a single loop); a second call retires the first.
export function nextAction(_: IpcMainInvokeEvent): Promise<Action[]> {
    if (queue.length > 0) {
        const actions = queue;
        queue = [];
        return Promise.resolve(actions);
    }
    waiter?.([]);
    return new Promise<Action[]>(resolve => {
        waiter = resolve;
    });
}
