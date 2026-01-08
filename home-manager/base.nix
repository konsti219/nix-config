# Pull global packages for nixos systems into home manager only systems as well
{
  pkgs,
  outputs,
  ...
} @ args: {
  home.packages = (outputs.nixosModules.packages args).environment.systemPackages;

  # Replacement for unwrapped ssh-agent
  programs.keychain.enable = true;
}
