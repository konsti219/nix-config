{
  config,
  inputs,
  lib,
  ...
}: let
  # Also exported, so the private flake builds its hosts exactly the same way
  mkConfigurations = {
    modules,
    hosts,
    mainUser,
    suffix ? "",
  }: let
    # Hosts get their own module on top of the shared base, in both classes
    modulesFor = class: name:
      [modules.${class}.base]
      ++ lib.optional (modules.${class} ? ${name}) modules.${class}.${name};

    nixosSystem = name: host:
      inputs.nixpkgs-stable.lib.nixosSystem {
        system = host.platform;
        modules =
          modulesFor "nixos" name
          ++ [
            {
              networking.hostName = "${name}${suffix}";
              home-manager.users.${mainUser}.imports = modulesFor "homeManager" name;
            }
          ];
      };
  in {
    nixosConfigurations = lib.mapAttrs' (name: host: lib.nameValuePair "${name}${suffix}" (nixosSystem name host)) hosts;
  };
in {
  flake = lib.mkMerge [
    {lib = {inherit mkConfigurations;};}

    # The public flake builds the secret-free variants of every host
    (mkConfigurations {
      modules = config.flake.modules;
      inherit (config) hosts mainUser;
      suffix = "-generic";
    })
  ];
}
