{config, ...}: let
  inherit (config) mainUser;
  inherit (config.flake.modules) homeManager;
in {
  hosts.hail = {};

  flake.modules.nixos.hail = {
    imports = [
      ./_hail/hardware-configuration.nix
      ./_hail/disks.nix
      ./_hail/gpu.nix
      ./_hail/virtualisation.nix
    ];

    system.stateVersion = "25.11"; # Don't change!

    users.users.${mainUser}.extraGroups = [
      "kvm"
      "libvirtd"
    ];
  };

  flake.modules.homeManager.hail = {
    imports = [homeManager.desktop];

    home.stateVersion = "25.11"; # Don't change!
  };
}
