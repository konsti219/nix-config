{config, ...}: let
  inherit (config) commonPackages;
in {
  # Pull global packages for nixos systems into home manager only systems as well
  flake.modules.homeManager.standalone = {pkgs, ...}: {
    home.packages = commonPackages pkgs;

    # Replacement for unwrapped ssh-agent
    programs.keychain.enable = true;
  };
}
