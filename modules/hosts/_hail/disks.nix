{
  config,
  pkgs,
  ...
}: {
  # Bootloader.
  # boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    theme = "${pkgs.kdePackages.breeze-grub}/grub/themes/breeze";
  };
}
