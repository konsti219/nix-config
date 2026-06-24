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
        (final: prev: {
          wayvr = inputs.wayvr.packages.${final.stdenv.hostPlatform.system}.default;
          wivrn = inputs.wayvr.packages.${final.stdenv.hostPlatform.system}.wivrn;
          wayvr-media-bridge = inputs.wayvr.packages.${final.stdenv.hostPlatform.system}.media-bridge;
          wayvr-ytmusic-extension = inputs.wayvr.packages.${final.stdenv.hostPlatform.system}.ytmusic-extension;
        })
      ];
    };
  };
}
