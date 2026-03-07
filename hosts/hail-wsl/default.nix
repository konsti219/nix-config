{
  lib,
  inputs,
  outputs,
  ...
} @ args: {
  hostName = "hail";

  # This host is only for home manager, so no nixos modules are needed.
  modules = with outputs.nixosModules; [];
  modulesSecret = with inputs.secrets.nixosModules; [];

  homeManagerModules = with outputs.homeManagerModules; [
    ({...}: {home.stateVersion = "25.11";}) # Don't change!
  ];
  homeManagerModulesSecret = with inputs.secrets.homeManagerModules; [home];
}
