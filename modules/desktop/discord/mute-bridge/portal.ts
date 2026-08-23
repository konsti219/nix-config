// Minimal client for org.freedesktop.portal.GlobalShortcuts.
//
// Uses dbus-native's raw message API rather than its proxy/introspection
// helpers: the portal's surface here is three method calls and two signals, and
// going through raw messages keeps the exact D-Bus signatures visible at the
// call sites.
//
// The portal ties a shortcut session to the lifetime of the D-Bus connection,
// so the connection this opens has to stay up for as long as shortcuts should
// keep working. Callers reconnect by calling connect() again.
import { Message, MessageBus, sessionBus, toPlain, Variant } from "dbus-native";

const PORTAL_BUS = "org.freedesktop.portal.Desktop";
const PORTAL_PATH = "/org/freedesktop/portal/desktop";
const SHORTCUTS_IFACE = "org.freedesktop.portal.GlobalShortcuts";
const REQUEST_IFACE = "org.freedesktop.portal.Request";
const SESSION_IFACE = "org.freedesktop.portal.Session";
const REGISTRY_IFACE = "org.freedesktop.host.portal.Registry";

export interface ShortcutSpec {
    id: string;
    description: string;
}

export interface ConnectOptions {
    /** Must match the .desktop file id, or the portal can't attribute the shortcuts. */
    appId: string;
    shortcuts: ShortcutSpec[];
    onActivated: (id: string) => void;
    /** Session closed, or the bus went away; the client is dead and must be replaced. */
    onClosed: (reason: string) => void;
    log?: (message: string) => void;
}

export interface ShortcutsClient {
    /** Shortcut ids the portal reports as bound. */
    bound: string[];
    close(): void;
}

let tokenCounter = 0;

function nextToken(prefix: string): string {
    return `vesktop_${prefix}_${process.pid}_${++tokenCounter}`;
}

/** Request/Session objects live under a path derived from our unique bus name. */
function senderToken(uniqueName: string): string {
    return uniqueName.replace(/^:/, "").replace(/\./g, "_");
}

/**
 * The bus assigns our unique name via Hello, which dbus-native issues itself on
 * connect; `bus.name` stays null until that reply lands. GetId is queued behind
 * Hello on the same connection to the same destination, so its reply arriving
 * means Hello's already did.
 */
async function waitForUniqueName(bus: MessageBus): Promise<string> {
    await bus.invokeDbus({ member: "GetId" });
    if (!bus.name) throw new Error("bus did not assign a unique name");
    return bus.name;
}

function shortcutIds(results: Record<string, any>): string[] {
    const shortcuts = results?.shortcuts;
    if (!Array.isArray(shortcuts)) return [];
    // Each entry is a (sa{sv}) struct, read as [id, metadata].
    return shortcuts.map((entry: any) => entry?.[0]).filter((id: any): id is string => typeof id === "string");
}

export async function connect(options: ConnectOptions): Promise<ShortcutsClient> {
    const { appId, shortcuts, onActivated, onClosed, log = () => {} } = options;

    const bus = sessionBus();
    let closed = false;

    const fail = (reason: string) => {
        if (closed) return;
        closed = true;
        onClosed(reason);
    };

    try {
        const sender = senderToken(await waitForUniqueName(bus));

        /**
         * Invoke a portal method that answers asynchronously via a Request
         * object. The reply path is derived from the handle_token we pass in,
         * so the listener is installed before the call goes out and the
         * Response signal cannot be missed.
         */
        const callRequest = async (
            member: string,
            signature: string,
            body: unknown[],
            token: string
        ): Promise<Record<string, any>> => {
            const path = `${PORTAL_PATH}/request/${sender}/${token}`;

            let settle: (value: [number, Record<string, any>]) => void;
            const response = new Promise<[number, Record<string, any>]>(resolve => {
                settle = resolve;
            });

            const onMessage = (msg: Message) => {
                if (msg.interface === REQUEST_IFACE && msg.member === "Response" && msg.path === path) {
                    const [code, results] = (msg.body ?? []) as [number, Record<string, any>];
                    settle([code, toPlain(results ?? {})]);
                }
            };

            await bus.addMatch(
                `type='signal',interface='${REQUEST_IFACE}',member='Response',path='${path}'`
            );
            bus.connection.on("message", onMessage);

            try {
                await bus.invoke({
                    destination: PORTAL_BUS,
                    path: PORTAL_PATH,
                    interface: SHORTCUTS_IFACE,
                    member,
                    signature,
                    body
                });
                const [code, results] = await response;
                // 1 = cancelled by the user, 2 = ended some other way.
                if (code !== 0) throw new Error(`${member} was rejected by the portal (response=${code})`);
                return results;
            } finally {
                bus.connection.removeListener("message", onMessage);
            }
        };

        // Without this, an unsandboxed app gets an empty app id and System
        // Settings has nothing sensible to label the entry with. Not fatal:
        // the shortcuts still work, they're just labelled poorly.
        await bus
            .invoke({
                destination: PORTAL_BUS,
                path: PORTAL_PATH,
                interface: REGISTRY_IFACE,
                member: "Register",
                signature: "sa{sv}",
                body: [appId, {}]
            })
            .catch((e: unknown) => log(`could not register app id: ${e}`));

        const createToken = nextToken("req");
        const created = await callRequest(
            "CreateSession",
            "a{sv}",
            [
                {
                    handle_token: new Variant("s", createToken),
                    session_handle_token: new Variant("s", nextToken("session"))
                }
            ],
            createToken
        );
        const session: string = created.session_handle;
        if (!session) throw new Error("portal returned no session_handle");

        // Bindings persist per app id across sessions, and KDE prompts on every
        // BindShortcuts call for ids it doesn't already know. Binding only what
        // is missing keeps the confirmation dialog to genuinely new shortcuts.
        const listToken = nextToken("req");
        let bound = shortcutIds(
            await callRequest("ListShortcuts", "oa{sv}", [session, { handle_token: new Variant("s", listToken) }], listToken)
        );

        const missing = shortcuts.filter(s => !bound.includes(s.id));
        if (missing.length > 0) {
            log(`binding new shortcuts: ${missing.map(s => s.id).join(", ")}`);
            const bindToken = nextToken("req");
            bound = shortcutIds(
                await callRequest(
                    "BindShortcuts",
                    "oa(sa{sv})sa{sv}",
                    [
                        session,
                        // Deliberately no preferred_trigger: the bindings show up
                        // unassigned in System Settings for manual assignment,
                        // rather than grabbing a combination already in use.
                        shortcuts.map(s => [s.id, { description: new Variant("s", s.description) }]),
                        "", // no parent window
                        { handle_token: new Variant("s", bindToken) }
                    ],
                    bindToken
                )
            );
        }

        const onSignal = (msg: Message) => {
            if (msg.interface === SHORTCUTS_IFACE && msg.member === "Activated") {
                const [sessionHandle, id] = (msg.body ?? []) as [string, string];
                if (sessionHandle === session && typeof id === "string") onActivated(id);
            } else if (msg.interface === SESSION_IFACE && msg.member === "Closed" && msg.path === session) {
                fail("portal closed the session");
            }
        };

        await bus.addMatch(`type='signal',interface='${SHORTCUTS_IFACE}',member='Activated'`);
        await bus.addMatch(`type='signal',interface='${SESSION_IFACE}',member='Closed',path='${session}'`);
        bus.connection.on("message", onSignal);

        bus.connection.on("end", () => fail("bus connection ended"));
        bus.connection.on("error", (e: Error) => fail(`bus error: ${e.message}`));

        log(`ready, shortcuts: ${bound.slice().sort().join(", ") || "none"}`);

        return {
            bound,
            close() {
                closed = true;
                try {
                    bus.connection.end();
                } catch {
                    /* already gone */
                }
            }
        };
    } catch (e) {
        try {
            bus.connection.end();
        } catch {
            /* already gone */
        }
        throw e;
    }
}
