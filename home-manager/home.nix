{ config, pkgs, outputs, host, ... }: {
  imports = [
    outputs.homeManagerModules.zsh
  ];

  home.username = host.mainUser;
  home.homeDirectory = "/home/${host.mainUser}";

  # Packages that should be installed to the user profile.
  home.packages = (with pkgs.unstable; [
    neofetch

    # Utils
    nnn
    zip
    xz
    unzip
    p7zip
    ripgrep
    jq
    fzf

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
    clang
    clang-tools
    (hiPrio gcc)
    gnumake
    rustup
    gh

    # Creative tools
    blender
    gimp
    orca-slicer

    # Other software
    discord
    prismlauncher
    superTuxKart
  ]) ++ (with pkgs; [
    yakuake
  ]);

  # git config
  programs.git = {
    enable = true;
    userName = "konsti219";
    userEmail = "37149441+konsti219@users.noreply.github.com";
    signing = {
      signByDefault = true;
      key = "65C10FB5A2BF4E55";
    };
    extraConfig = {
      core.editor = "codium --wait";
      credential = {
        "https://github.com".helper = "!/home/konsti/.nix-profile/bin/gh auth git-credential";
        "https://gist.github.com".helper = "!/home/konsti/.nix-profile/bin/gh auth git-credential";
      };
      url = {
        "https://github.com/".insteadof = "git@github.com:";
        "https://".insteadof = "git://";
      };
      init.defaultbranch = "main";
    };
  };

  home.stateVersion = "23.11"; # Don't change!

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
