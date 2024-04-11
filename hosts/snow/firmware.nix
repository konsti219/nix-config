# Firmware software for Framework
{ ... }: {
  # Enable firmware upgrader
  services.fwupd.enable = true;
  services.fwupd.extraRemotes = [ "lvfs-testing" ];

  # Enable fingerprint support
  services.fprintd.enable = true;

  # services.fprintd.tod.enable = true;
  # services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;
}
