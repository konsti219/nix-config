{
  home = import ./home.nix;

  base = import ./base.nix;
  desktop = import ./desktop.nix;
  zsh = import ./zsh;
}
