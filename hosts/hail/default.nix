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
      steam
      virtualisation
    ]);
  modulesSecret = with inputs.secrets.nixosModules; [
    vpn
  ];

  homeManagerModules = with outputs.homeManagerModules; [
    desktop
    ({...}: {home.stateVersion = "25.11";}) # Don't change!
  ];
  homeManagerModulesSecret = with inputs.secrets.homeManagerModules; [home];
}
