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

      # Misc
      cowsay
      which
      gnused
      gnutar
      gawk
      zstd
      gparted
      glow
      yubioath-flutter
      imagemagickBig

      # Dev tools
      android-studio
      (hiPrio clang)
      clang-tools
      gcc
      gnumake
      gdb
      # pwndbg
      nasm
      rustup
      gh
      arduino-ide
      python3
      vscode

      # Creative tools
      pkgs.blender
      gimp3
      orca-slicer

      # Other software
      pkgs.discord
      prismlauncher
      superTuxKart
    ])
    ++ (with pkgs; [
      kdePackages.yakuake
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

  # gdb config
  home.file.".gdbinit".text = ''
    set disassembly-flavor intel
    set print pretty on
    alias di = disas /r $pc, +
    alias ri = starti
    # alias ui = tui enable
    alias ui = python import gdb ; print(gdb.execute("tui enable")) ; print(gdb.execute("la asm")) ; print(gdb.execute("disas /r $pc, +1"))
    alias uir = la reg
    alias di1 = disas /r $pc, +1
  '';
  home.file.".gdbearlyinit".text = ''
    set startup-quietly on
  '';

  # Enable eza with icons for mainUser
  programs.eza = {
    enable = true;
    icons = "auto";
  };

  home.stateVersion = "23.11"; # Don't change!

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
