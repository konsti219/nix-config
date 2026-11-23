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

      # plasma6 still ships drkonqi's units; keep only the crash notification path
      systemd.user.services = {
        # the launcher lingers until its notification is dismissed
        "drkonqi-coredump-launcher@" = {
          overrideStrategy = "asDropin";
          serviceConfig.RuntimeMaxSec = "1h";
          # keep the session PATH so "Details" can find drkonqi-coredump-gui
          environment = {
            PATH = lib.mkForce null;
            LOCALE_ARCHIVE = lib.mkForce null;
            TZDIR = lib.mkForce null;
          };
        };
        drkonqi-coredump-pickup.enable = false;
        drkonqi-sentry-postman.enable = false;
      };
      systemd.user.paths.drkonqi-sentry-postman.enable = false;
      systemd.user.timers.drkonqi-sentry-postman.enable = false;

      # plasmashell ignores SIGTERM on shutdown and always burns its full 40s timeout
      systemd.user.services.plasma-plasmashell = {
        overrideStrategy = "asDropin";
        serviceConfig.TimeoutStopSec = 5;
        # nulls drop the global defaults so the unit keeps the session PATH it launches apps with
        environment = {
          PATH = lib.mkForce null;
          LOCALE_ARCHIVE = lib.mkForce null;
          TZDIR = lib.mkForce null;
        };
      };

      # KDE Connect
      programs.kdeconnect.enable = true;
    };
}
