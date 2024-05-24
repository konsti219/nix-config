# Configure zsh
{pkgs, ...}: {
  home.shellAliases = {
    # anti-prank prank
    vi = "loginctl lock-session #";
    vim = "loginctl lock-session #";
    nvim = "loginctl lock-session #";

    # TODO: depuplicate from nixos/general.nix
    ls = "eza";
    ll = "eza -l";
    l = "eza -la";
  };
  programs.bash.enable = true;
  programs.zsh = {
    enable = true;
    history.size = 16384;

    enableCompletion = true;
    autosuggestion.enable = true;

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];
    initExtra = ''
      if [[ -r "$\{XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-$\{(%):-%n}.zsh" ]]; then
        source "$\{XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-$\{(%):-%n}.zsh"
      fi

      source ${./.p10k.zsh}

      export PATH="$PATH:$HOME/.cargo/bin"
    '';

    oh-my-zsh = {
      enable = true;
      plugins = ["git"];
    };
  };
}
