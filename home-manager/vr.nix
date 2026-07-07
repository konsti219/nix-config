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

      tmp="$(mktemp "$state_dir/clipboard-sync.XXXXXX")"
      trap 'rm -f "$tmp"' EXIT

      # Pick which Wayland offer to mirror. Prefer real image data so that
      # screenshots reach XWayland apps as image/png instead of being
      # flattened to text/plain (which made images paste as garbled text).
      wl_image_type() {
        local types t
        types="$(wl-paste --list-types 2>/dev/null || true)"
        while IFS= read -r t; do
          [ "$t" = image/png ] && { echo image/png; return; }
        done <<<"$types"
        while IFS= read -r t; do
          case "$t" in image/*) echo "$t"; return ;; esac
        done <<<"$types"
        echo ""
      }

      # Does the X11 clipboard advertise an image target?
      x11_image_type() {
        local t
        while IFS= read -r t; do
          [ "$t" = image/png ] && { echo image/png; return; }
        done <<<"$(xclip -selection clipboard -o -t TARGETS 2>/dev/null || true)"
        echo ""
      }

      # Forward $tmp only when it differs from the last payload we synced,
      # so the two directions can't ping-pong forever.
      commit() {
        if ! cmp -s "$tmp" "$state_file" 2>/dev/null; then
          cp "$tmp" "$state_file"
          "$@" <"$tmp" >/dev/null 2>&1 || true
        fi
      }

      case "''${1-}" in
        --to-x11)
          ty="$(wl_image_type)"
          if [ -n "$ty" ]; then
            wl-paste --type "$ty" >"$tmp" 2>/dev/null || true
            commit xclip -selection clipboard -t "$ty" -in
          else
            wl-paste --no-newline >"$tmp" 2>/dev/null || true
            commit xclip -selection clipboard -in
          fi
          exit 0
          ;;
        --to-wayland)
          ty="$(x11_image_type)"
          if [ -n "$ty" ]; then
            xclip -selection clipboard -o -t "$ty" >"$tmp" 2>/dev/null || true
            commit wl-copy --type "$ty"
          else
            xclip -selection clipboard -o >"$tmp" 2>/dev/null || true
            commit wl-copy
          fi
          exit 0
          ;;
      esac

      # Initial sync in both directions, then watch for changes.
      "$0" --to-x11 || true
      "$0" --to-wayland || true

      wl-paste --watch "$0" --to-x11 &
      while sleep 1; do
        "$0" --to-wayland || true
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
