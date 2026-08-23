{
  config,
  inputs,
  ...
}: let
  inherit (config.flake.modules) homeManager;
in {
  hosts.snow = {};

  flake.modules.nixos.snow = {
    imports = [
      ./_snow/hardware-configuration.nix
      inputs.nixos-hardware.nixosModules.framework-13th-gen-intel
      inputs.lanzaboote.nixosModules.lanzaboote
      ./_snow/disks.nix
      ./_snow/firmware.nix
    ];

    system.stateVersion = "23.11"; # Don't change!
  };

  flake.modules.homeManager.snow = {
    imports = [homeManager.desktop];

    home.stateVersion = "23.11"; # Don't change!
  };
}
