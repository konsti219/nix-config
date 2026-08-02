// Main-process half: registers voice-mute shortcuts with the desktop portal and
// hands each activation to the renderer.
import { IpcMainInvokeEvent } from "electron";

import { connect, ShortcutsClient } from "./portal";

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
