# Services for auth and logon and stuff. Mainly gnupg and ssh.
{ ... }: {
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  services.pcscd.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    # require public key authentication
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };
}

