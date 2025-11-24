# Options relating to Virtualisation
{
  host,
  pkgs,
  ...
}: {
  # virtualisation.virtualbox.host.enable = true;
  # users.extraGroups.vboxusers.members = [host.mainUser];
  # virtualisation.virtualbox.host.package = pkgs.unstable.virtualbox;

  environment.systemPackages = [
    # pkgs.unstable.qemu
  ];
  # virtualisation.libvirtd.enable = true;

  boot.kernelParams = ["kvm.enable_virt_at_load=0"];

  virtualisation.podman = {
    enable = true;
    extraPackages = [
      pkgs.podman-compose
    ];
    autoPrune = {
      enable = true;
      dates = "daily";
    };

    dockerCompat = true;
    dockerSocket.enable = true;
  };
  environment.variables = {
    PODMAN_COMPOSE_WARNING_LOGS = "false";
  };
}
