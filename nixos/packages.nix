{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    vim
    nano

    file
    eza
    bat
    wget
    tree
    git
    dnsutils
    alejandra

    htop
    fastfetch
  ];

  environment.shellAliases = {
    ls = "eza";
    ll = "eza -l";
    l = "${pkgs.printpath}/bin/printpath.sh";
    cat = "bat";
    neofetch = "fastfetch";
  };
}
