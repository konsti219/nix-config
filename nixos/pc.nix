# Settings for personal machines like Desktops or Laptops
{
  pkgs,
  config,
  inputs,
  host,
  ...
}: let
  # Turn all ratbag-managed *mice* that have LEDs on/off.
  # Keyboards are skipped (the G915 handles its own idle-off in firmware).
  # Enumerates devices dynamically, so it survives alias changes and new mice.
  ledColor = "ffffff"; # ratbagd zeros color on mode off, explicitly set it again
  mouseLedIdle = pkgs.writeShellApplication {
    name = "mouse-led-idle";
    runtimeInputs = [pkgs.unstable.libratbag pkgs.gawk pkgs.coreutils];
    text = ''
      mode="$1" # "on" or "off"
      ratbagctl list | cut -d: -f1 | while read -r dev; do
        [ -n "$dev" ] || continue
        info=$(ratbagctl "$dev" info 2>/dev/null) || continue
        devtype=$(printf '%s\n' "$info" | awk -F': *' '/Device Type/{print $2; exit}')
        [ "$devtype" = "Mouse" ] || continue
        leds=$(printf '%s\n' "$info" | awk -F': *' '/Number of Leds/{print $2; exit}')
        [ -n "$leds" ] && [ "$leds" -gt 0 ] || continue
        i=0
        while [ "$i" -lt "$leds" ]; do
          if [ "$mode" = "on" ]; then
            ratbagctl "$dev" led "$i" set mode on color ${ledColor} 2>/dev/null || true
          else
            ratbagctl "$dev" led "$i" set mode off 2>/dev/null || true
          fi
          i=$((i + 1))
        done
      done
    '';
  };
in {
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

  hardware.graphics = {
    enable = true;
    package = pkgs.unstable.mesa;
    package32 = pkgs.unstable.pkgsi686Linux.mesa;
  };

  # OBS virtual camera (OBS itself is installed via home-manager)
  boot.extraModulePackages = [config.boot.kernelPackages.v4l2loopback];
  boot.kernelModules = ["v4l2loopback"];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=9 card_label="OBS Virtual Camera" exclusive_caps=1
  '';

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
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxcb
  ];

  programs.firefox = {
    package = pkgs.unstable.firefox;
    enable = true;
  };

  # General Desktop software
  environment.systemPackages = with pkgs; [
    thunderbird
    unstable.vscode
    unstable.nil
    btop
    wireshark
    gparted
    qpwgraph
    inputs.pipemeeter.packages.${pkgs.stdenv.hostPlatform.system}.default
    piper
    chromium
  ];
  services.flatpak.enable = true;

  security.wrappers.btop = {
    source = "${pkgs.btop}/bin/btop";
    capabilities = "cap_perfmon+ep";
    owner = "root";
    group = "root";
  };

  programs.wireshark.enable = true;
  services.davfs2.enable = true;

  services.ratbagd = {
    enable = true;
    package = pkgs.unstable.libratbag;
  };

  # After 10 min idle, turn off mouse LEDs; turn back on when activity resumes.
  # swayidle shares KWin's ext-idle-notify-v1 clock, so it stays in sync with
  # Plasma's own screen-off timeout (also 10 min).
  systemd.user.services.mouse-led-idle = {
    description = "Turn off mouse LEDs when idle";
    wantedBy = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    after = ["graphical-session.target"];
    serviceConfig = {
      ExecStart = ''${pkgs.swayidle}/bin/swayidle -w timeout 600 "${mouseLedIdle}/bin/mouse-led-idle off" resume "${mouseLedIdle}/bin/mouse-led-idle on"'';
      Restart = "on-failure";
    };
  };
  users.users.${host.mainUser} = {
    extraGroups = ["games"];
  };
}
