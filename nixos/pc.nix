# Settings for personal machines like Desktops or Laptops
{
  pkgs,
  inputs,
  ...
}: {
  # Enable support for Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  # services.blueman.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  hardware.graphics.enable = true;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Fonts
  fonts = {
    enableDefaultPackages = false;
    packages = with pkgs; [
      # pathched default fonts
      dejavu_fonts
      #freefont_ttf # breaks things
      gyre-fonts # TrueType substitutes for standard PostScript fonts
      liberation_ttf
      unifont
      noto-fonts-color-emoji

      # custom fonts
      meslo-lgs-nf
      nerd-fonts.fira-code
      nerd-fonts.droid-sans-mono
      nerd-fonts.meslo-lg
    ];
  };
  # tty font
  console.font = "Lat2-Terminus16";

  # Enable nix ld
  programs.nix-ld.enable = true;
  # Sets up all the libraries to load
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    fuse3
    icu
    nss
    openssl
    curl
    expat
    glib
    nspr
    at-spi2-core
    cups
    libdrm
    dbus
    gtk3
    pango
    cairo
    libgbm
    libxkbcommon
    alsa-lib
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libxcb
  ];

  # General Desktop software
  environment.systemPackages = with pkgs; [
    firefox
    thunderbird
    unstable.vscodium
    unstable.nil
    wireshark
    gparted
    qpwgraph
  ];
  services.flatpak.enable = true;
  programs.wireshark.enable = true;
  services.davfs2.enable = true;
}
