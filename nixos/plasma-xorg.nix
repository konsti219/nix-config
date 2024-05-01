# Plasma 5 Configuration with XServer
{pkgs, ...}: {
  # Use xkbOptions in tty.
  console.useXkbConfig = true;

  # =======
  # Xserver
  # =======

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Configure keymap in X11 [BROKEN]
  services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e,caps:escape";
  services.xserver.xkbOptions = "eurosign:e;lv3:ralt_switch";

  # ===
  # KDE
  # ===

  # Enable the Plasma 5 Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  environment.systemPackages = [
    pkgs.libsForQt5.bluedevil
  ];

  # KDE Connect
  programs.kdeconnect = {
    enable = true;
    package =
      pkgs.libsForQt5.kdeconnect-kde.overrideAttrs
      (oldAttrs: {
        buildInputs = (oldAttrs.buildInputs or []) ++ [pkgs.libsForQt5.qtconnectivity];
        cmakeFlags = (oldAttrs.cmakeFlags or []) ++ ["-DBLUETOOTH_ENABLED=ON"];
      });
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
