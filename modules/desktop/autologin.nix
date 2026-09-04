{config, ...}: let
  inherit (config) mainUser;
in {
  flake.modules.nixos.hail = {
    services.displayManager.autoLogin = {
      enable = true;
      user = mainUser;
    };

    # Longer credential cache than the 15min default on this always-on desktop
    security.sudo-rs.extraConfig = "Defaults timestamp_timeout=30";
  };
}
