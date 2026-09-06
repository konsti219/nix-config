{
  flake.modules = {
    nixos.hail = {
      pkgs,
      config,
      lib,
      ...
    }: rec {
      services.wivrn = {
        enable = true;
        package = pkgs.unstable.wivrn;
        autoStart = true;
        openFirewall = true;
        steam.importOXRRuntimes = true;
        steam.package = config.programs.steam.package;
        config.enable = true;
        config.json = {
          application = [pkgs.unstable.wayvr];
          openvr-compat-path = "${pkgs.unstable.xrizer}/lib/xrizer";
        };
      };

      networking.firewall.allowedUDPPorts = [6969];

      # Headless server runs 24/7 so the GUI is only a viewer
      systemd.user.services.slimevr-server = {
        description = "SlimeVR server";
        wantedBy = ["default.target"];
        # Heap defaults scale to a fraction of RAM; the live set is ~27M
        environment.JDK_JAVA_OPTIONS = "-Xms64m -Xmx128m";
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.unstable.slimevr-server} run";
          Restart = "on-failure";
        };
      };

      environment.systemPackages = with pkgs.unstable; [
        wayvr
        nvtopPackages.amd
        slimevr
        bs-manager
      ];

      programs.firefox = {
        # Use dev edition to install unsigned extensions
        package = lib.mkForce pkgs.unstable.firefox-devedition;
        nativeMessagingHosts.packages = [
          pkgs.kdePackages.plasma-browser-integration
          pkgs.unstable.wayvr-media-bridge
        ];

        policies.ExtensionSettings = {
          "wayvr-ytmusic@konsti" = {
            installation_mode = "force_installed";
            install_url = "file://${pkgs.unstable.wayvr-ytmusic-extension}/wayvr-ytmusic@konsti.xpi";
          };
        };
      };
    };

    homeManager.hail = {
      pkgs,
      config,
      ...
    }: {
      xdg = {
        configFile."wayvr" = {
          source = ./wayvr;
          recursive = true;
          force = true;
        };

        configFile."openvr/openvrpaths.vrpath" = {
          force = true;
          text = let
            steam = "${config.xdg.dataHome}/Steam";
          in
            builtins.toJSON {
              version = 1;
              jsonid = "vrpathreg";

              external_drivers = null;
              config = ["${steam}/config"];

              log = ["${steam}/logs"];

              runtime = [
                "${pkgs.unstable.xrizer}/lib/xrizer"
              ];
            };
        };
      };
    };
  };
}
