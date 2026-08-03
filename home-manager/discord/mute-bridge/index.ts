// Renderer half: waits on native.ts for portal global-shortcut activations and
// applies them via Discord's own self-mute action, and reports the muted state
// back so the main process can badge the window icon.
import { Logger } from "@utils/Logger";
import definePlugin, { PluginNative } from "@utils/types";
import { findByPropsLazy, findStoreLazy } from "@webpack";

const Native = VencordNative.pluginHelpers.DiscordMuteBridge as PluginNative<typeof import("./native")>;

const logger = new Logger("DiscordMuteBridge");

const MediaEngineStore = findStoreLazy("MediaEngineStore");
const SelectedChannelStore = findStoreLazy("SelectedChannelStore");
const VoiceActions = findByPropsLazy("toggleSelfMute");

const ERROR_BACKOFF_MS = 2000;

type Action = "toggle" | "mute" | "unmute";

function applyAction(action: Action): void {
    if (typeof VoiceActions?.toggleSelfMute !== "function") {
        logger.error("Could not locate Discord's toggleSelfMute action; mute command ignored.");
        return;
    }
    try {
        if (action !== "toggle") {
            const isMuted: unknown = MediaEngineStore?.isSelfMute?.();
            const want = action === "mute";
            if (typeof isMuted === "boolean" && isMuted === want) return;
        }
        VoiceActions.toggleSelfMute({ usedKeybind: true });
    } catch (e) {
        logger.error("Failed to apply mute action", e);
    }
}

/**
 * Muted *and* actually in a call. Being self-muted while not connected to voice
 * is not worth badging, since it has no effect until you join one.
 */
function isMutedInCall(): boolean {
    try {
        if (SelectedChannelStore?.getVoiceChannelId?.() == null) return false;
        return MediaEngineStore?.isSelfMute?.() === true;
    } catch (e) {
        logger.error("Could not read the voice state", e);
        return false;
    }
}

let reportedMuted: boolean | null = null;

function syncIcon(): void {
    const muted = isMutedInCall();
    if (muted === reportedMuted) return;
    reportedMuted = muted;
    Native.setMuted(muted).catch((e: unknown) => logger.error("Failed to update the window icon", e));
}

// Bumped on stop() so an in-flight nextAction() that resolves after a restart
// can't apply its actions or keep a stale loop alive.
let generation = 0;

async function loop(mine: number): Promise<void> {
    while (mine === generation) {
        let actions: Action[];
        try {
            actions = await Native.nextAction();
        } catch (e) {
            logger.error("Lost contact with the shortcut helper; retrying", e);
            await new Promise(r => setTimeout(r, ERROR_BACKOFF_MS));
            continue;
        }
        if (mine !== generation) return;
        for (const action of actions) applyAction(action);
    }
}

export default definePlugin({
    name: "DiscordMuteBridge",
    description:
        "Toggle your own voice mute from a desktop global shortcut, bound through the xdg-desktop-portal GlobalShortcuts API. Assign the keys in System Settings > Shortcuts > Vesktop.",
    authors: [{ name: "konsti", id: 0n }],
    enabledByDefault: true,

    start() {
        void loop(++generation);

        // Both stores matter: the mute state itself, and whether we are in a
        // call at all. Listening here rather than only reacting to our own
        // shortcut means the badge also tracks the in-app mute button.
        MediaEngineStore?.addChangeListener?.(syncIcon);
        SelectedChannelStore?.addChangeListener?.(syncIcon);
        syncIcon();
    },

    stop() {
        generation++;
        MediaEngineStore?.removeChangeListener?.(syncIcon);
        SelectedChannelStore?.removeChangeListener?.(syncIcon);
        // Leave the icon in a sane state rather than stuck showing muted.
        reportedMuted = null;
        Native.setMuted(false).catch(() => {});
    }
});
