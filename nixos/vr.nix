{
  pkgs,
  lib,
  inputs,
  ...
}: rec {
  services.wivrn = {
    enable = true;
    package = pkgs.unstable.wivrn;
    autoStart = true;
    openFirewall = true;
    steam.importOXRRuntimes = true;
    config.enable = true;
    config.json = {
      application = [pkgs.unstable.wayvr];
      openvr-compat-path = "${pkgs.unstable.xrizer}/lib/xrizer";
    };
  };

  networking.firewall.allowedUDPPorts = [6969];

  environment.systemPackages = with pkgs.unstable; [
    wayvr
    nvtopPackages.amd
    vrcx
    slimevr
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
}
