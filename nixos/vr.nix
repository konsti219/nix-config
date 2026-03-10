{pkgs, lib, inputs, ...}: {
  services.wivrn = {
    enable = true;
    package = pkgs.unstable.wivrn;
    autoStart = true;
    openFirewall = true;
    defaultRuntime = true;
    steam.importOXRRuntimes = true;
    config.json.openvr-compat-path = "${pkgs.unstable.opencomposite}/lib/opencomposite";
  };

  systemd.user.services = {
    # wayvr = {
    #   description = "wayvr";
    #   after = [ "wivrn.service" ];
    #   requires = [ "wivrn.service" ];
    #   partOf = [ "wivrn.service" ];

    #   serviceConfig = {
    #     ExecStart = "${lib.getExe pkgs.unstable.wayvr} --openxr --replace";
    #     Restart = "on-failure";
    #   };
    # };
  };

  networking.firewall.allowedUDPPorts = [ 6969 ];

  environment.systemPackages = with pkgs.unstable; [
    slimevr
    vrcx
    wayvr
  ];
}
