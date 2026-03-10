# Shared configs for various aspects
{
  general = import ./general.nix;
  home-manager = import ./home-manager.nix;

  autologin = import ./autologin.nix;
  android-dev = import ./android-dev.nix;
  auth = import ./auth.nix;
  locale = import ./locale.nix;
  nixpkgs = import ./nixpkgs.nix;
  packages = import ./packages.nix;
  pc = import ./pc.nix;
  plasma = import ./plasma.nix;
  remote = import ./remote.nix;
  steam = import ./steam.nix;
  virtualisation = import ./virtualisation.nix;
  vr = import ./vr.nix;
}
