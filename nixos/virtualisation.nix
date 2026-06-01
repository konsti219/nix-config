# Options relating to Virtualisation
{pkgs, ...}: {
  # virtualisation.virtualbox.host.enable = true;
  # virtualisation.virtualbox.host.package = pkgs.unstable.virtualbox;

  virtualisation.podman = {
    enable = true;
    extraPackages = [
      pkgs.podman-compose
    ];
    autoPrune = {
      enable = true;
      dates = "daily";
    };

    dockerCompat = true;
    dockerSocket.enable = true;
  };
  environment.variables = {
    PODMAN_COMPOSE_WARNING_LOGS = "false";
  };
  environment.shellAliases = {
    pc = "podman compose";
  };
}
