# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });

    # Patch kwin to provide more metadata for screencasts
    kdePackages = prev.kdePackages.overrideScope (_kfinal: kprev: {
      kwin = kprev.kwin.overrideAttrs (old: {
        patches =
          (old.patches or [])
          ++ [../home-manager/discord/auto-audio/kwin-screencast-metadata.patch];
      });

      # Let a window icon set via xdg-toplevel-icon-v1 win over the launcher's
      # icon, so the Vesktop mute badge shows in the Icons-only Task Manager.
      # KWin already delivers the icon; libtaskmanager is the only place that
      # drops it. Upstream deliberately prefers the launcher icon (kde#356609,
      # reaffirmed for this protocol in kde#459735), so this is not expected to
      # land upstream in this form; drop the patch if that ever changes.
      plasma-workspace = kprev.plasma-workspace.overrideAttrs (old: {
        patches =
          (old.patches or [])
          ++ [../home-manager/discord/mute-bridge/plasma-taskmanager-toplevel-icon.patch];
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
}
