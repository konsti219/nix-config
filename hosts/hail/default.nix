{
  lib,
  inputs,
  outputs,
  ...
} @ args: {
  hostName = "hail";

  modules =
    [
      ./hardware-configuration.nix
      ./disks.nix
      ./gpu.nix
      ({...}: {system.stateVersion = "25.11";}) # Don't change!
    ]
    ++ (with outputs.nixosModules; [
      general
      home-manager

      auth
      autologin
      android-dev
      locale
      pc
      plasma
      remote
      steam
      virtualisation
      vr
    ]);
  modulesSecret = with inputs.secrets.nixosModules; [
    vpn
  ];

  homeManagerModules = with outputs.homeManagerModules; [
    desktop
    vr
    ({...}: {home.stateVersion = "25.11";}) # Don't change!
  ];
  homeManagerModulesSecret = with inputs.secrets.homeManagerModules; [home];
}
