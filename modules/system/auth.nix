{
  flake.modules.nixos.base =
    # Services for auth and logon and stuff. Mainly gnupg and ssh.
    {...}: {
      # programs.mtr.enable = true;
      programs.gnupg.agent = {
        enable = true;
        # enableSSHSupport = true;
        settings = {
          default-cache-ttl = 3600;
          max-cache-ttl = 3600;
        };
      };
      services.pcscd.enable = true;
      programs.ssh = {
        startAgent = true;
        agentTimeout = null;
      };
    };
}
