# Genral config to be used across all systems
{
  lib,
  pkgs,
  outputs,
  host,
  ...
}: {
  # ====
  # Boot
  # ====

  # Use latest Linux kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
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
  #networking.firewall.allowedTCPPorts = [ ... ];
  #networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # ============
  # Nix Settings
  # ============

  # Enable new cli and flakes
  nix.settings.experimental-features = ["nix-command" "flakes"];
  # TODO: remove once 2.21+ is in stable. This is a fix for broken nix store.
  nix.package = pkgs.nixVersions.nix_2_21;

  # The only unfree packages allowed are listed here.
  # nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "android-studio-stable"
      "discord"
      "steam"
      "steam-original"
      "steam-run"
      "zerotierone"
    ];

  nixpkgs.overlays = [
    outputs.overlays.unstable-packages
  ];

  # ========
  # Packages
  # ========

  environment.systemPackages = with pkgs; [
    vim
    nano

    file
    eza
    wget
    tree
    git
    alejandra

    htop
    btop
    fastfetch
  ];

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
    ls = "eza";
    ll = "eza -l";
    l = "eza -la";
    sudo = "doas";
    neofetch = "fastfetch";
  };
}
