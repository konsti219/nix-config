{
  flake.modules.nixos.base =
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

      # Useless on NixOS
      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        drkonqi
        discover
      ];

      # plasmashell ignores SIGTERM on shutdown and always burns its full 40s timeout
      systemd.user.services.plasma-plasmashell = {
        overrideStrategy = "asDropin";
        serviceConfig.TimeoutStopSec = 5;
      };

      # KDE Connect
      programs.kdeconnect.enable = true;
    };
}
