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

      environment.systemPackages = with pkgs.unstable; [
        wayvr
        nvtopPackages.amd
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
      };
    };
  };
}
