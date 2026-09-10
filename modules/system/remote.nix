{config, ...}: let
  inherit (config) mainUser;

  # Sunshine captures one output per process, so hail runs an instance per monitor
  monitors = {
    dp1 = {
      output = "DP-1";
      port = 47989;
    };
    dp2 = {
      output = "DP-2";
      port = 48989;
    };
  };

  tcpOffsets = [(-5) 0 1 21];
  udpOffsets = [9 10 11 13 21];
in {
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    home.packages = [pkgs.unstable.moonlight-qt];
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

    stateDir = name: "${config.users.users.${mainUser}.home}/.local/state/sunshine-${name}";

    configFile = name: monitor:
      (pkgs.formats.keyValue {}).generate "sunshine-${name}.conf" {
        sunshine_name = "${config.networking.hostName} ${monitor.output}";
        inherit (monitor) port;
        # kms capture enumerates no outputs under KWin and silently falls back to software x264
        capture = "kwin";
        encoder = "vaapi";
        adapter_name = "/dev/dri/renderD128";
        output_name = monitor.output;
        file_apps = "${apps}";
        # Both instances share $HOME, so keep every writable path per-instance
        credentials_file = "${stateDir name}/credentials.json";
        file_state = "${stateDir name}/state.json";
        log_path = "${stateDir name}/sunshine.log";
        pkey = "${stateDir name}/cert.key";
        cert = "${stateDir name}/cert.crt";
      };

    ports = offsets: lib.concatMap (m: map (o: m.port + o) offsets) (lib.attrValues monitors);
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
      allowedTCPPorts = ports tcpOffsets;
      allowedUDPPorts = ports udpOffsets;
    };

    systemd.user.services = lib.mapAttrs' (name: monitor:
      lib.nameValuePair "sunshine-${name}" {
        description = "Sunshine stream host for ${monitor.output}";

        wantedBy = ["graphical-session.target"];
        partOf = ["graphical-session.target"];
        wants = ["graphical-session.target"];
        # Autologin can otherwise start this before KWin owns the screencast protocol
        after = ["graphical-session.target" "plasma-kwin_wayland.service"];

        startLimitIntervalSec = 500;
        startLimitBurst = 5;

        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.sunshine} ${configFile name monitor}";
          Restart = "on-failure";
          RestartSec = "5s";
          StateDirectory = "sunshine-${name}";
        };
      })
    monitors;
  };
}
