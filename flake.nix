{
  description = "NixOS config flake";

  inputs = {
    # Stable 25.05 NixOS/nixpkgs
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    # Unstable NixOS/nixpkgs
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # NixOS Hardware GitHub repo
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Home Manger GitHub repo
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    # lanzaboote (secure boot)
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    # Private NixOS/Home Manager modules that are excluded in *-generic hosts
    secrets = {
      url = "git+ssh://github.com_konsti219/konsti219/nix-config-secrets.git?ref=main";
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
    configLib = import ./lib.nix args;

    # Define main user
    mainUser = "konsti";

    # List of all hosts for each platform
    systems = {
      x86_64-linux = [(import ./hosts/snow args)];
    };

    # Helper function to generate a set of attributes for each system
    forSystems = configLib.forSystems systems;
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
    nixosConfigurations = configLib.systemsToConfig systems mainUser;

    # Formatter for nix code in this flake
    formatter = forSystems (
      system: nixpkgs-stable.legacyPackages.${system}.alejandra
    );
  };
}
