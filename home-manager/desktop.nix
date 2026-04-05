{pkgs, ...}: {
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

    # Other software
    vesktop
    discord
    signal-desktop
    prismlauncher
    parsec-bin
  ];
}
