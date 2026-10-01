{
  description = "NixOS config flake";

  inputs = {
    # Stable 26.05 NixOS/nixpkgs
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Unstable NixOS/nixpkgs
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs-unstable.url = "github:NixOS/nixpkgs/master"; # Master branch: fastest updates, least cache

    # Last unstable on glibc 2.42, for libs loaded into stable processes; drop once 26.11 is out
    nixpkgs-glibc242.url = "github:NixOS/nixpkgs/4975466d324710c576dc11ad614684e6bd8cad8e";

    # Flake output framework
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-stable";
    };

    # Imports every file under ./modules as a flake-parts module
    import-tree.url = "github:vic/import-tree";

    # NixOS Hardware GitHub repo
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    # Home Manger GitHub repo
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # lanzaboote (secure boot)
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    pipemeeter = {
      url = "github:konsti219/pipemeeter";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    wayvr = {
      url = "github:konsti219/wayvr";
      # xrizer and the WiVRn client get loaded into games
      inputs.nixpkgs.follows = "nixpkgs-glibc242";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      imports = [
        inputs.flake-parts.flakeModules.modules
        (inputs.import-tree ./modules)
      ];
    };
}
