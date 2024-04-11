# Plasma 5 Configuration with XServer
{ ... }: {
  # Use xkbOptions in tty.
  console.useXkbConfig = true;

  # =======
  # Xserver
  # =======

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the Plasma 5 Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Configure keymap in X11 [BROKEN]
  services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e,caps:escape";
  services.xserver.xkbOptions = "eurosign:e;lv3:ralt_switch";
}
