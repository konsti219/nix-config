# Steam config
{
  pkgs,
  inputs,
  ...
}: {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    gamescopeSession.enable = true;
    protontricks.enable = true;

    extraCompatPackages = with pkgs.unstable; [
      # pkgs.proton-ge-rtsp-bin
      proton-ge-bin
    ];

    package = pkgs.unstable.steam.override {
      extraProfile = ''
        unset TZ
        export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
      '';
    };
  };
  hardware.graphics.enable32Bit = true; # Enables support for 32bit libs that steam uses

  programs.gamescope = {
    enable = true;
    capSysNice = false;
  };

  environment.systemPackages = with pkgs.unstable; [
    gamescope-wsi # gamescope hdr support
    protonplus
  ];

  hardware.steam-hardware.enable = true;
  boot.kernelModules = ["ntsync"];
}
