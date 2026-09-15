{lib, ...}: let
  commonPackages = pkgs:
    with pkgs; [
      vim
      nano

      file
      eza
      bat
      wget
      tree
      git
      dnsutils
      alejandra

      htop
      fastfetch
    ];

  commonAliases = pkgs: {
    ll = "eza -l";
    l = "${pkgs.printpath}/bin/printpath.sh";
    cat = "bat";
    neofetch = "fastfetch";
  };
in {
  # Shared with home-manager, which needs the same values under other options
  options = {
    commonPackages = lib.mkOption {
      type = lib.types.functionTo (lib.types.listOf lib.types.package);
      description = "Packages installed on every system, as a function of pkgs.";
    };

    commonAliases = lib.mkOption {
      type = lib.types.functionTo (lib.types.attrsOf lib.types.str);
      description = "Shell aliases set on every system, as a function of pkgs.";
    };
  };

  config = {
    inherit commonPackages commonAliases;

    flake.modules.nixos.base = {pkgs, ...}: {
      environment.systemPackages = commonPackages pkgs;
      environment.shellAliases = commonAliases pkgs;
    };
  };
}
