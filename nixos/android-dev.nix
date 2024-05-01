# Settings for developing Android apps
{
  pkgs,
  host,
  ...
}: {
  # Enable adb
  programs.adb.enable = true;
  services.udev.packages = [
    pkgs.android-udev-rules
  ];
  users.extraGroups.adbusers.members = [host.mainUser];
}
