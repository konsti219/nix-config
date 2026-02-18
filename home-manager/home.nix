{
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
  home.packages = with pkgs.unstable; [
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
    btop

    # Networking tools
    mtr # A network diagnostic tool
    iperf3
    dnsutils
    ldns
    socat
    nmap
    iptables
    # ipscan
    wireguard-tools

    # Misc
    cowsay
    which
    gnused
    gnutar
    gawk
    zstd
    glow
    imagemagickBig

    # Dev tools
    (lib.hiPrio clang)
    clang-tools
    gcc
    gnumake
    just
    gdb
    # pwndbg
    nasm
    rustup
    gh
    (pkgs.python3.withPackages (python-pkgs: [
      python-pkgs.requests
      python-pkgs.python-dotenv
      python-pkgs.numpy
      python-pkgs.pandas
      python-pkgs.matplotlib
    ]))
    uv
  ];

  # git config
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
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

  # Enable direnv for easier flake usage
  programs.direnv = {
    enable = true;
    silent = true;
    nix-direnv.enable = true;
  };

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
