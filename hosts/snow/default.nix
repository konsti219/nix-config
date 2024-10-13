{
  lib,
  inputs,
  outputs,
  ...
} @ args: {
  hostName = "snow";

  modules =
    [
      ./hardware-configuration.nix
      inputs.nixos-hardware.nixosModules.framework-13th-gen-intel
      ./disks.nix
      ./firmware.nix
      ({...}: {system.stateVersion = "23.11";}) # Don't change!
    ]
    ++ (with outputs.nixosModules; [
      general
      home-manager

      android-dev
      auth
      locale
      pc
      plasma
      steam
      virtualisation
    ]);
  modulesSecret = with inputs.secrets.nixosModules; [zerotier];

  homeManagerModules = with outputs.homeManagerModules; [];
  homeManagerModulesSecret = with inputs.secrets.homeManagerModules; [home];
}
