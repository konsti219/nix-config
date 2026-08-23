{...}: {
  # Home manager only, so no NixOS system is built for it
  hosts.hail-wsl = {
    hostName = "hail";
    nixos = false;
  };

  flake.modules.homeManager.hail-wsl = {
    home.stateVersion = "25.11"; # Don't change!
  };
}
