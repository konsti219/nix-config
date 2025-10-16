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

  virtualisation.docker.enable = true;
  # users.extraGroups.docker.members = [host.mainUser]; # enabling this allows for a trivial privilege escalation
  environment.shellAliases = {
    docker = "sudo docker";
  };
}
