{pkgs, ...}: {
  # Discord (+ Vencord + DiscordMuteBridge plugin + global-mute wiring)
  imports = [./discord];

  # Desktop specific packages
  home.packages = with pkgs.unstable; [
    yubioath-flutter
    pkgs.kdePackages.yakuake
    gparted

    # Dev tools
    android-studio
    arduino-ide

    # Creative tools
    pkgs.blender
    gimp3
    vlc

    # Other software
    signal-desktop
    prismlauncher
    parsec-bin
  ];
}
