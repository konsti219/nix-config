{
  description = "NixOS config flake";

  inputs = {
    # The flake in the current directory.
    # currentDir.url = ".";

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
  };

  outputs = {
    self,
    nixpkgs-stable,
    nixpkgs-unstable,
    home-manager,
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
    platformNames = builtins.attrNames systems;
    systemValues =
      map
      (
        platform:
          map
          (host: {
            name = host.hostName;
            value = {
              inherit platform;
              hostName = host.hostName;
              modules = host.modules;
              homeManagerModules = host.homeManagerModules;
              inherit mainUser;
            };
          })
          systems.${platform}
      )
      platformNames;
    systemConfig = builtins.listToAttrs (lib.lists.flatten systemValues);

    # Helper function to generate a set of attributes for each system
    forSystems = lib.genAttrs platformNames;
  in {
    # Custom packages
    packages = forSystems (system: import ./pkgs nixpkgs-unstable.legacyPackages.${system});

    # Custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};
    # Reusable nixos modules
    nixosModules = import ./nixos;
    # Reusable home-manager modules
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
      systemConfig;

    # Formatter for nix code in this flake
    formatter = forSystems (
      system: nixpkgs-stable.legacyPackages.${system}.alejandra
    );
  };
}
