# Plasma 5 Configuration with XServer
{pkgs, ...}: {
  # ===
  # KDE
  # ===

  # Enable the Plasma 5 Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  environment.systemPackages = [
    pkgs.libsForQt5.bluedevil
  ];

  # KDE Connect
  programs.kdeconnect.enable = true;
  networking.firewall = {
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
  };
}
