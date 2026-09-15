{pkgs, ...}: {
  # amd_iommu=on is not a valid value; the kernel rejects it and enables AMD-Vi anyway.
  boot.kernelParams = ["iommu=pt"];

  boot.initrd.kernelModules = [
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];

  boot.extraModprobeConfig = ''
    options vfio-pci ids=1002:13c0,1002:1640
  '';

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true;
    };
  };

  virtualisation.spiceUSBRedirection.enable = true;
  programs.virt-manager.enable = true;

  # Let a plain user-run QEMU (~/vm, no libvirt) open the passed-through iGPU.
  services.udev.extraRules = ''
    SUBSYSTEM=="vfio", GROUP="kvm", MODE="0660"
  '';

  # VFIO pins the whole guest RAM, so the 8 MiB default memlock is not enough.
  security.pam.loginLimits = [
    {
      domain = "@kvm";
      type = "-";
      item = "memlock";
      value = "unlimited";
    }
  ];

  environment.systemPackages = with pkgs; [
    virt-viewer
  ];
}
