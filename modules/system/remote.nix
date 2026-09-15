{config, ...}: let
  inherit (config) mainUser;

  port = 47989;
  tcpOffsets = [(-5) 0 1 21];
  udpOffsets = [9 10 11 13 21];
in {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    home.packages = [pkgs.unstable.moonlight-qt];
  };

  # Shadow the launcher, so clicking it can't start an unconfigured instance next to the unit.
  # The sibling .kwin.desktop that grants screencast access is a different file and stays visible.
  flake.modules.homeManager.hail = {
    home.file.".local/share/applications/dev.lizardbyte.app.Sunshine.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Sunshine
      NoDisplay=true
      Hidden=true
    '';
  };

  flake.modules.nixos.hail = {
    config,
    lib,
    pkgs,
    ...
  }: let
    apps = (pkgs.formats.json {}).generate "sunshine-apps.json" {
      env = {};
      apps = [
        {
          name = "Desktop";
          image-path = "desktop.png";
        }
      ];
    };

    stateDir = "${config.users.users.${mainUser}.home}/.local/state/sunshine";

    configFile = (pkgs.formats.keyValue {}).generate "sunshine.conf" {
      sunshine_name = config.networking.hostName;
      inherit port;
      # kms capture enumerates no outputs under KWin and silently falls back to software x264
      capture = "kwin";
      # vaapi can't load radeonsi_drv_video.so (libva ABI skew against the vendored ffmpeg)
      encoder = "vulkan";
      adapter_name = "/dev/dri/renderD128";
      # Only the initial output; Ctrl+Alt+Shift+F1/F2… switches mid-stream in KDE output priority order
      output_name = "DP-1";
      # Quitting from the tray exits cleanly, which Restart=on-failure won't bring back
      system_tray = "disabled";
      file_apps = "${apps}";
      credentials_file = "${stateDir}/credentials.json";
      file_state = "${stateDir}/state.json";
      log_path = "${stateDir}/sunshine.log";
      pkey = "${stateDir}/cert.key";
      cert = "${stateDir}/cert.crt";
    };
  in {
    environment.systemPackages = [pkgs.sunshine];

    hardware.uinput.enable = true;
    services.udev.packages = [pkgs.sunshine];
    # Sunshine ships no udev rules, so /dev/uinput access comes from hardware.uinput's group
    users.users.${mainUser}.extraGroups = ["input" "uinput"];

    services.avahi = {
      enable = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };

    networking.firewall = {
      allowedTCPPorts = map (o: port + o) tcpOffsets;
      allowedUDPPorts = map (o: port + o) udpOffsets;
    };

    systemd.user.services.sunshine = {
      description = "Sunshine stream host";

      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      wants = ["graphical-session.target"];
      # Autologin can otherwise start this before KWin owns the screencast protocol
      after = ["graphical-session.target" "plasma-kwin_wayland.service"];

      startLimitIntervalSec = 500;
      startLimitBurst = 5;

      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.sunshine} ${configFile}";
        Restart = "on-failure";
        RestartSec = "5s";
        StateDirectory = "sunshine";
      };
    };
  };
}
