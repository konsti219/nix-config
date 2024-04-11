# Options relating to Virtualisation
{ host, ... }: {
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ host.mainUser ];

  # virtualisation.docker.enable = true;
  # users.extraGroups.docker.members = [ host.mainUser ];
}

