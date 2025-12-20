# Genral config to be used across all systems
{
  pkgs,
  outputs,
  host,
  ...
}: {
  imports = [outputs.nixosModules.nixpkgs];

  # ====
  # Boot
  # ====

  # Use latest Linux kernel
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # For better interop
  boot.supportedFilesystems = ["ntfs"];

  # ==========
  # Networking
  # ==========

  networking.hostName = host.hostName;
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [5000 5201];
  networking.firewall.allowedUDPPorts = [5000 5201];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

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
      users = [host.mainUser];
      keepEnv = true;
      persist = true;
    }
  ];

  environment.shellAliases = {
    sudo = "doas";
  };
}
