{
  lib,
  outputs,
  ...
}: {
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
    outputs.overlays.additions
    outputs.overlays.modifications
    outputs.overlays.unstable-packages
  ];
}
