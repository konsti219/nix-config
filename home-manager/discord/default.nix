# Discord + Vencord with the DiscordMuteBridge userplugin and a CLI, so a
# manually-assigned KDE shortcut can toggle voice mute without X11 keystroke access.
{
  pkgs,
  lib,
  ...
}: let
  upkgs = pkgs.unstable;

  # Inject in preBuild, not postPatch: pnpmDeps inherits postPatch, and the
  # plugin adds no deps, so this keeps the pinned pnpm hash valid.
  vencordWithBridge = upkgs.vencord.overrideAttrs (old: {
    preBuild =
      (old.preBuild or "")
      + ''
        mkdir -p src/userplugins/discordMuteBridge
        cp ${./mute-bridge/index.ts} src/userplugins/discordMuteBridge/index.ts
        cp ${./mute-bridge/native.ts} src/userplugins/discordMuteBridge/native.ts
      '';
  });

  discordWithBridge = upkgs.discord.override {
    withVencord = true;
    vencord = vencordWithBridge;
  };

  discord-mute = pkgs.writeShellApplication {
    name = "discord-mute";
    runtimeInputs = [pkgs.socat];
    text = ''
      action="''${1:-toggle}"
      case "$action" in
        toggle | mute | unmute) ;;
        *)
          echo "usage: discord-mute [toggle|mute|unmute]" >&2
          exit 2
          ;;
      esac

      if ! printf '%s\n' "$action" | socat -u - ABSTRACT-CONNECT:discord-mute-bridge 2>/dev/null; then
        echo "discord-mute: could not reach the bridge." >&2
        echo "  Is Discord running with the DiscordMuteBridge plugin enabled?" >&2
        exit 1
      fi
    '';
  };
in {
  home.packages = [
    discordWithBridge
    discord-mute
  ];

  # Launcher to bind a shortcut to in System Settings (unassigned by default).
  xdg.desktopEntries.discord-mute-toggle = {
    name = "Discord Mute Toggle";
    genericName = "Toggle Discord voice mute";
    exec = "${lib.getExe discord-mute} toggle";
    icon = "discord";
    terminal = false;
    type = "Application";
    noDisplay = true;
    startupNotify = false;
  };
}
