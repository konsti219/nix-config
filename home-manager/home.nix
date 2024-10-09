{
  config,
  pkgs,
  outputs,
  host,
  ...
}: {
  imports =
    [
      outputs.homeManagerModules.zsh
    ]
    ++ host.homeManagerModules;

  home.username = host.mainUser;
  home.homeDirectory = "/home/${host.mainUser}";

  # Packages that should be installed to the user profile.
  home.packages =
    (with pkgs.unstable; [
      # Utils
      nnn
      zip
      xz
      unzip
      p7zip
      ripgrep
      jq
      fzf
      comma
      screen

      # Networking tools
      mtr # A network diagnostic tool
      iperf3
      dnsutils # `dig` + `nslookup`
      ldns
      socat
      nmap
      iptables
      ipscan
      wireguard-tools
      wireshark-qt

      # Misc
      cowsay
      which
      gnused
      gnutar
      gawk
      zstd
      gparted
      glow
      yubikey-manager-qt

      # Dev tools
      android-studio
      (hiPrio clang)
      clang-tools
      gcc
      gnumake
      rustup
      gh
      arduino-ide

      # Creative tools
      blender
      gimp
      orca-slicer

      # Other software
      pkgs.discord
      prismlauncher
      superTuxKart
    ])
    ++ (with pkgs; [
      yakuake
    ]);

  # git config
  programs.git = {
    enable = true;
    lfs.enable = true;
    extraConfig = {
      core.editor = "codium --wait";
      init.defaultbranch = "main";
    };
  };

  home.stateVersion = "23.11"; # Don't change!

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
