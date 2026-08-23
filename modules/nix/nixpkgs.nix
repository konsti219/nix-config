{config, ...}: let
  inherit (config.flake) overlays;

  nixpkgs = {lib, ...}: {
    # The only unfree packages allowed are listed here.
    # nixpkgs.config.allowUnfree = true;
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "android-studio-stable"
        "discord"
        "steam"
        "steam-original"
        "steam-run"
        "steam-unwrapped"
        "zerotierone"
        "displaylink"
      ];

    nixpkgs.overlays = [
      overlays.additions
      overlays.modifications
      overlays.unstable-packages
    ];
  };
in {
  # Also used on its own by the standalone home-manager configurations
  flake.modules = {
    generic.nixpkgs = nixpkgs;
    nixos.base.imports = [nixpkgs];
  };
}
