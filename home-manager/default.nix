{
  home = import ./home.nix;

  base = import ./base.nix;
  desktop = import ./desktop.nix;
  vr = import ./vr.nix;
  zsh = import ./zsh;
}
