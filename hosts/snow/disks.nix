{...}: {
  # Full disk encryption setup
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    enableCryptodisk = true;
  };

  boot.initrd = {
    luks.devices."root" = {
      device = "/dev/disk/by-uuid/0286aef5-438c-4960-922a-ecd1b6fac994"; # UUID for /dev/nvme01np2
      preLVM = true;
      keyFile = "/keyfile0.bin";
      allowDiscards = true;
    };
    secrets = {
      "keyfile0.bin" = "/etc/secrets/initrd/keyfile0.bin";
    };
  };
}
