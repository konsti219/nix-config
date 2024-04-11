{ pkgs, ... }: {
  # Define main user account
  users.users.konsti = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = with pkgs.unstable; [
      iptables
      wireguard-tools
      gparted
      android-studio
      clang
      clang-tools
      discord
      gh
      gnumake
      ipscan
      rustup
      vscodium
      wireshark-qt
      yubikey-manager-qt
    ] ++ [
      pkgs.yakuake
    ];
    shell = pkgs.zsh;
  };

  # Define guest account
  users.users.guest = {
    isNormalUser = true;
  };
}
