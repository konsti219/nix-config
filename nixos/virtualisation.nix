# Options relating to Virtualisation
{
  host,
  pkgs,
  ...
}: {
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [host.mainUser];
  virtualisation.virtualbox.host.package = pkgs.virtualbox;

  virtualisation.docker.enable = true;
  users.extraGroups.docker.members = [host.mainUser];
}
