# Plasma 6 Configuration with Wayland
{
  pkgs,
  lib,
  config,
  ...
}: {
  # ===
  # KDE
  # ===

  environment.variables = {
    KWIN_DRM_PREFER_COLOR_DEPTH = "24";
  };

  # Enable the Plasma Desktop Environment.
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };
    defaultSession = "plasma";
  };
  services.desktopManager.plasma6.enable = true;

  # KDE Connect
  programs.kdeconnect.enable = true;
}
