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

    package = pkgs.unstable.steam.override {
      extraProfile = ''
        unset TZ
        export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
        export PRESSURE_VESSEL_IMPORT_OPENXR_1_LAYERS=1
        export GBM_BACKENDS_PATH="$(realpath /run/opengl-driver/lib/gbm)"
        export PRESSURE_VESSEL_FILESYSTEMS_RO="/nix/store''${PRESSURE_VESSEL_FILESYSTEMS_RO:+:$PRESSURE_VESSEL_FILESYSTEMS_RO}"
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

  systemd.user.slices.steam = {
    sliceConfig.MemoryMax = "64G";
  };
  systemd.user.units."app-steam@.service" = {
    overrideStrategy = "asDropin";
    text = ''
      [Service]
      Slice=steam.slice
      OOMPolicy=continue
    '';
  };

  hardware.steam-hardware.enable = true;
  boot.kernelModules = ["ntsync"];

  # The 32bit steam client does unaligned atomics, which trap on AMD bus lock
  # detection and spam the journal with "took a bus_lock trap" warnings.
  boot.kernelParams = ["split_lock_detect=off"];
}
