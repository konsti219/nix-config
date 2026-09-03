{config, ...}: let
  inherit (config) mainUser;
in {
  flake.modules.nixos.base =
    # Genral config to be used across all systems
    {pkgs, ...}: {
      # ====
      # Boot
      # ====

      # Use latest Linux kernel
      boot.kernelPackages = pkgs.unstable.linuxPackages_latest;
      # For better interop
      boot.supportedFilesystems = ["ntfs"];

      # ==========
      # Networking
      # ==========

      # Pick only one of the below networking options.
      # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
      networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

      # No WWAN hardware on either host, and NetworkManager pulls it in by default
      networking.modemmanager.enable = false;

      # Configure network proxy if necessary
      # networking.proxy.default = "http://user:password@proxy:port/";
      # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

      # Open ports in the firewall.
      networking.firewall.allowedTCPPorts = [5000 5201];
      networking.firewall.allowedUDPPorts = [5000 5201];
      # Or disable the firewall altogether.
      # networking.firewall.enable = false;

      # =======
      # Logging
      # =======

      services.journald.rateLimitBurst = 1000;

      # ============
      # Nix Settings
      # ============

      # Enable new cli and flakes
      nix.settings.experimental-features = ["nix-command" "flakes"];

      # ========
      # Security
      # ========

      security.sudo.enable = false;
      security.doas.enable = true;
      security.doas.extraRules = [
        {
          users = [mainUser];
          keepEnv = true;
          persist = true;
        }
      ];

      environment.shellAliases = {
        sudo = "doas";
      };
    };
}
