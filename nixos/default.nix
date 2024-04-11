# Shared configs for various aspects
{
  general = import ./general.nix;

  android-dev = import ./android-dev.nix;
  auth = import ./auth.nix;
  locale = import ./locale.nix;
  pc = import ./pc.nix;
  plasma-xorg = import ./plasma-xorg.nix;
  steam = import ./steam.nix;
  virtualisation = import ./virtualisation.nix;
  zerotier = import ./zerotier.nix;
  zsh = import ./zsh.nix;
}
