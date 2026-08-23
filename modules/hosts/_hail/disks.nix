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
    extraEntries = ''
      menuentry "Windows" {
        insmod part_gpt
        insmod fat
        search --no-floppy --fs-uuid --set=root F20B-76FF
        chainloader /EFI/Microsoft/Boot/bootmgfw.efi
      }
    '';
  };
}
