{
  flake.modules.nixos.base =
    # Steam config
    {pkgs, ...}: {
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

      # The 32bit steam client does unaligned atomics, which trap on AMD bus lock
      # detection and spam the journal with "took a bus_lock trap" warnings.
      boot.kernelParams = ["split_lock_detect=off"];
    };
}
