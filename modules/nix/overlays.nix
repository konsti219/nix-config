# This file defines overlays
{inputs, ...}: let
  keepLocal = drv: drv.overrideAttrs (_: {preferLocalBuild = true;});
  localStdenv = pkgs:
    pkgs.stdenv
    // {
      mkDerivation = args: pkgs.stdenv.mkDerivation (args // {preferLocalBuild = true;});
    };
in {
  flake.overlays = {
    # This one brings our custom packages from the 'pkgs' directory
    additions = final: _prev: import ../../pkgs final;

    # This one contains whatever you want to overlay
    # You can change versions, add patches, set compilation flags, anything really.
    # https://nixos.wiki/wiki/Overlays
    modifications = final: prev: {
      # example = prev.example.overrideAttrs (oldAttrs: rec {
      # ...
      # });

      displaylink = keepLocal prev.displaylink;

      # Patch kwin for screencast metadata and focus-independent clipboard export
      kdePackages = prev.kdePackages.overrideScope (_kfinal: kprev: {
        kwin = kprev.kwin.overrideAttrs (old: {
          patches =
            (old.patches or [])
            ++ [
              ../desktop/discord/auto-audio/kwin-screencast-metadata.patch
              ../gaming/vr/kwin-xwl-clipboard-unfocused.patch
            ];
        });

        # Let a window icon set via xdg-toplevel-icon-v1 win over the launcher's
        # icon, so the Vesktop mute badge shows in the Icons-only Task Manager.
        plasma-workspace = kprev.plasma-workspace.overrideAttrs (old: {
          patches =
            (old.patches or [])
            ++ [../desktop/discord/mute-bridge/plasma-taskmanager-toplevel-icon.patch];
        });
      });
    };

    # When applied, the unstable nixpkgs set (declared in the flake inputs) will
    # be accessible through 'pkgs.unstable'
    unstable-packages = final: _prev: {
      unstable = import inputs.nixpkgs-unstable {
        system = final.stdenv.hostPlatform.system;
        config.allowUnfree = true;
        overlays = [
          # Use newer libratbag
          (ufinal: uprev: {
            libratbag = uprev.libratbag.overrideAttrs (oldAttrs: {
              version = "unstable-2026-05-31";
              src = ufinal.fetchFromGitHub {
                owner = "libratbag";
                repo = "libratbag";
                rev = "2fb9a701e8c02bbe261eb141ff311a379837c63d";
                hash = "sha256-c4nAVhI3m9VeGy+rZLPS8Z98RS9JbrHe/mdiuee5y4s=";
              };
            });
          })
          (_ufinal: uprev: {
            android-studio = uprev.android-studio.override {stdenv = localStdenv uprev;};
            vscode = keepLocal uprev.vscode;
            steam-unwrapped = keepLocal uprev.steam-unwrapped;
          })
          # Include wayvr overlay to have it in unstable
          (final: _prev: let
            wayvrPackages = inputs.wayvr.packages.${final.stdenv.hostPlatform.system};
          in {
            wayvr = wayvrPackages.default;
            wivrn = wayvrPackages.wivrn;
            xrizer = wayvrPackages.xrizer;
            wayvr-media-bridge = wayvrPackages.media-bridge;
            wayvr-ytmusic-extension = wayvrPackages.ytmusic-extension;
          })
        ];
      };
    };
  };
}
