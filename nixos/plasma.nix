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

  # DisplayLink
  environment.systemPackages = with pkgs; [
    displaylink
  ];
  boot = {
    extraModulePackages = [config.boot.kernelPackages.evdi];
    initrd.kernelModules = ["evdi"];
  };
  systemd.services.displaylink-server = {
    enable = true;
    requires = ["systemd-udevd.service"];
    after = ["systemd-udevd.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.displaylink}/bin/DisplayLinkManager";
      User = "root";
      Group = "root";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
