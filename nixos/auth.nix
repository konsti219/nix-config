# Services for auth and logon and stuff. Mainly gnupg and ssh.
{...}: {
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    # enableSSHSupport = true;
  };
  services.pcscd.enable = true;
  programs.ssh = {
    startAgent = true;
    agentTimeout = null;
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    # require public key authentication
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };
}
