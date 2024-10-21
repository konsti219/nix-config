{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.lanzaboote.nixosModules.lanzaboote];

  # Bootloader.

  # replaced by lanzaboote
  # boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-30581918-9274-4b25-8b7a-1fd13d07ddcf".device = "/dev/disk/by-uuid/30581918-9274-4b25-8b7a-1fd13d07ddcf";

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  environment.systemPackages = [
    # For debugging and troubleshooting Secure Boot.
    pkgs.sbctl
  ];
}
