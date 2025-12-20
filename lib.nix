{
  lib,
  inputs,
  outputs,
} @ args: rec {
  # Transform into datastructure for nixosConfiguration
  systemsToVariants = systems: mainUser:
    lib.attrsets.mapAttrsToList (platform: systems:
      map (host: [
        # Generic version
        {
          name = host.hostName + "-generic";
          value = {
            inherit platform;
            hostName = host.hostName + "-generic";
            modules = host.modules;
            homeManagerModules = host.homeManagerModules;
            inherit mainUser;
          };
        }
        # Version with secrets
        {
          name = host.hostName;
          value = {
            inherit platform;
            hostName = host.hostName;
            modules = host.modules ++ host.modulesSecret;
            homeManagerModules = host.homeManagerModules ++ host.homeManagerModulesSecret;
            inherit mainUser;
          };
        }
      ])
      systems)
    systems;

  variantsToConfig = systems: mainUser: builtins.listToAttrs (lib.lists.flatten (lib.lists.flatten (systemsToVariants systems mainUser)));

  systemsToConfig = systems: mainUser:
    builtins.mapAttrs
    (_name: host:
      lib.nixosSystem {
        system = host.platform;
        specialArgs = {inherit lib inputs outputs host;};
        modules = host.modules;
      })
    (variantsToConfig systems mainUser);

  systemsToHomeConfig = systems: mainUser:
    builtins.mapAttrs
    (_name: host:
      inputs.home-manager-unstable.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs-unstable.legacyPackages.${host.platform};
        extraSpecialArgs = {
          inherit inputs outputs host;
        };
        modules = [
          outputs.nixosModules.nixpkgs # Bit of a hack to get nixpkgs configured correctly
          outputs.homeManagerModules.base
          ./home-manager/home.nix
        ];
      })
    (variantsToConfig systems mainUser);

  forSystems = systems: lib.genAttrs (builtins.attrNames systems);
}
