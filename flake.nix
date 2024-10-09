{
  description = "NixOS config flake";

  inputs = {
    # Stable 24.05 NixOS/nixpkgs
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";

    # Unstable NixOS/nixpkgs
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # NixOS Hardware GitHub repo
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Home Manger GitHub repo
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    # Private NixOS/Home Manager modules that are excluded in *-generic hosts
    secrets = {
      url = "git+ssh://github.com_konsti219/konsti219/nix-config-secrets.git?shallow=1";
      inputs = {
        nixpkgs-stable.follows = "nixpkgs-stable";
        nixpkgs-unstable.follows = "nixpkgs-unstable";
      };
    };
  };

  outputs = {
    self,
    nixpkgs-stable,
    nixpkgs-unstable,
    home-manager,
    secrets,
    ...
  } @ inputs: let
    inherit (self) outputs;
    lib = nixpkgs-stable.lib;
    args = {inherit inputs outputs lib;};

    # Define main user
    mainUser = "konsti";

    # List of all hosts for each platform
    systems = {
      x86_64-linux = [(import ./hosts/snow args)];
    };

    # Transform into datastructure for nixosConfiguration
    systemsPlatformHostsVariants = lib.attrsets.mapAttrsToList (platform: systems:
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
    systemsVariants = builtins.listToAttrs (lib.lists.flatten (lib.lists.flatten systemsPlatformHostsVariants));

    # Helper function to generate a set of attributes for each system
    platformNames = builtins.attrNames systems;
    forSystems = lib.genAttrs platformNames;
  in {
    # Custom packages
    packages = forSystems (system: import ./pkgs nixpkgs-unstable.legacyPackages.${system});

    # Custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};
    # Reusable NixOS modules
    nixosModules = import ./nixos;
    # Reusable Home Manager modules
    homeManagerModules = import ./home-manager;

    # NixOS Hosts
    nixosConfigurations =
      builtins.mapAttrs
      (_name: host:
        lib.nixosSystem {
          system = host.platform;
          specialArgs = {inherit lib inputs outputs host;};
          modules = host.modules;
        })
      systemsVariants;

    # Formatter for nix code in this flake
    formatter = forSystems (
      system: nixpkgs-stable.legacyPackages.${system}.alejandra
    );
  };
}
