# Settings for developing Android apps
{
  pkgs,
  host,
  ...
}: {
  # Enable adb
  programs.adb.enable = true;
  users.extraGroups.adbusers.members = [host.mainUser];
}
