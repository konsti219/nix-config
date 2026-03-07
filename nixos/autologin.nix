{host, ...}: {
  services.displayManager.autoLogin = {
    enable = true;
    user = host.mainUser;
  };
}
