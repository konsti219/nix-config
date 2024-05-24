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
  programs.kdeconnect = {
    enable = true;
    # package =
    #   pkgs.libsForQt5.kdeconnect-kde.overrideAttrs
    #   (oldAttrs: {
    #     buildInputs = (oldAttrs.buildInputs or []) ++ [pkgs.libsForQt5.qtconnectivity];
    #     cmakeFlags = (oldAttrs.cmakeFlags or []) ++ ["-DBLUETOOTH_ENABLED=ON"];
    #   });
  };
  networking.firewall = {
    enable = true;
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
