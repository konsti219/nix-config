{
  pkgs,
  lib,
  config,
  ...
}: let
  clipboardSync = pkgs.writeShellApplication {
    name = "clipboard-sync";
    runtimeInputs = with pkgs; [
      coreutils
      wl-clipboard
      xclip
    ];
    text = ''
      set -eu

      state_dir="''${XDG_RUNTIME_DIR:-/tmp}"
      state_file="$state_dir/clipboard-sync.last"

      sync() {
        cat >"$tmp" || true
        if ! cmp -s "$tmp" "$state_file" 2>/dev/null; then
          cp "$tmp" "$state_file"
          "$@" <"$tmp" >/dev/null 2>&1 || true
        fi
      }

      tmp="$(mktemp "$state_dir/clipboard-sync.XXXXXX")"
      trap 'rm -f "$tmp"' EXIT

      case "''${1-}" in
        --to-wayland)
          sync wl-copy
          exit 0
          ;;
        --to-x11)
          sync xclip -selection clipboard -in
          exit 0
          ;;
      esac

      wl-paste --no-newline 2>/dev/null | "$0" --to-x11 || true
      xclip -selection clipboard -out 2>/dev/null | "$0" --to-wayland || true

      wl-paste --watch "$0" --to-x11 &
      while sleep 1; do
        xclip -selection clipboard -out 2>/dev/null | "$0" --to-wayland || true
      done &
      wait
    '';
  };
in {
  xdg = {
    configFile."wayvr" = {
      source = ./wayvr;
      recursive = true;
      force = true;
    };

    configFile."openvr/openvrpaths.vrpath" = {
      force = true;
      text = let
        steam = "${config.xdg.dataHome}/Steam";
      in
        builtins.toJSON {
          version = 1;
          jsonid = "vrpathreg";

          external_drivers = null;
          config = ["${steam}/config"];

          log = ["${steam}/logs"];

          runtime = [
            "${pkgs.unstable.xrizer}/lib/xrizer"
          ];
        };
    };
  };

  systemd.user.services.clipboard-sync = {
    Unit = {
      Description = "Keep Wayland and X11 clipboards in sync";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      ExecStart = lib.getExe clipboardSync;
      Restart = "always";
      RestartSec = 1;
    };

    Install.WantedBy = ["graphical-session.target"];
  };
}
