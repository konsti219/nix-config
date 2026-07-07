// Renderer half: polls native.ts for mute commands and applies them via
// Discord's own self-mute action.
import { Logger } from "@utils/Logger";
import definePlugin, { PluginNative } from "@utils/types";
import { findByPropsLazy, findStoreLazy } from "@webpack";

const Native = VencordNative.pluginHelpers.DiscordMuteBridge as PluginNative<typeof import("./native")>;

const logger = new Logger("DiscordMuteBridge");

const MediaEngineStore = findStoreLazy("MediaEngineStore");
const VoiceActions = findByPropsLazy("toggleSelfMute");

const POLL_MS = 120;

type Action = "toggle" | "mute" | "unmute";

function applyAction(action: Action): void {
    const toggle = VoiceActions?.toggleSelfMute;
    if (typeof toggle !== "function") {
        logger.error("Could not locate Discord's toggleSelfMute action; mute command ignored.");
        return;
    }
    try {
        if (action === "toggle") {
            toggle();
            return;
        }
        const isMuted: unknown = MediaEngineStore?.isSelfMute?.();
        const want = action === "mute";
        if (typeof isMuted === "boolean" && isMuted === want) return;
        toggle();
    } catch (e) {
        logger.error("Failed to apply mute action", e);
    }
}

let interval: ReturnType<typeof setInterval> | undefined;

export default definePlugin({
    name: "DiscordMuteBridge",
    description:
        "Toggle your own voice mute via an external unix socket, for compositor-level global shortcuts. Paired with the `discord-mute` CLI.",
    authors: [{ name: "konsti", id: 0n }],
    enabledByDefault: true,

    start() {
        interval = setInterval(async () => {
            let actions: Action[];
            try {
                actions = await Native.consumeActions();
            } catch {
                return;
            }
            for (const a of actions) applyAction(a);
        }, POLL_MS);
    },

    stop() {
        if (interval) clearInterval(interval);
        interval = undefined;
    }
});
