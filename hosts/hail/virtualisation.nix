{
  host,
  pkgs,
  ...
}: {
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
  ];

  boot.initrd.kernelModules = [
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];

  boot.extraModprobeConfig = ''
    options vfio-pci ids=1002:13c0,1002:1640 disable_vga=1
  '';

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true;
    };
  };

  virtualisation.spiceUSBRedirection.enable = true;
  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    virt-viewer
  ];

  users.users.${host.mainUser}.extraGroups = [
    "kvm"
    "libvirtd"
  ];
}
