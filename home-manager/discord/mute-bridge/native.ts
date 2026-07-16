// Main-process half: listens on an abstract-namespace unix socket for mute
// commands from the `discord-mute` CLI and queues them for the renderer to
// apply. Abstract sockets have no filesystem entry, so runtime-dir cleanup
// can't delete them and they're auto-released when the process exits.
import { IpcMainInvokeEvent } from "electron";
import { createServer, Server, Socket } from "net";

type Action = "toggle" | "mute" | "unmute";

// Leading NUL = Linux abstract namespace (appears as @discord-mute-bridge).
const SOCKET_ADDR = "\0discord-mute-bridge";

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
        server.listen(SOCKET_ADDR);
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
