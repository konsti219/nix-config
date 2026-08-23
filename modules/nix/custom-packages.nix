{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    ...
  }: {
    _module.args.pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};

    # Custom packages
    packages = import ../../pkgs pkgs;

    # Formatter for nix code in this flake
    formatter = inputs.nixpkgs-stable.legacyPackages.${system}.alejandra;
  };
}
