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
}
