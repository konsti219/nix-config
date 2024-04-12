{ config, pkgs, host, ... }: {
  imports = [
    ./zsh.nix
  ];

  home.username = host.mainUser;
  home.homeDirectory = "/home/${host.mainUser}";

  # Packages that should be installed to the user profile.
  home.packages = (with pkgs.unstable; [
    neofetch
    nnn # terminal file manager

    # archives
    zip
    xz
    unzip
    p7zip

    # utils
    ripgrep # recursively searches directories for a regex pattern
    jq # A lightweight and flexible command-line JSON processor
    yq-go # yaml processor https://github.com/mikefarah/yq
    fzf # A command-line fuzzy finder

    # networking tools
    mtr # A network diagnostic tool
    iperf3
    dnsutils # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc # it is a calculator for the IPv4/v6 addresses
    iptables
    ipscan
    wireguard-tools
    wireshark-qt

    # misc
    cowsay
    which
    gnused
    gnutar
    gawk
    zstd
    gparted
    glow # markdown previewer in terminal

    android-studio
    clang
    clang-tools
    (hiPrio gcc)
    gnumake
    rustup
    gh

    yubikey-manager-qt
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
