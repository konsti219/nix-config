# Configure zsh
{
  pkgs,
  outputs,
  ...
} @ args: {
  home.shellAliases =
    {
      # useful shorthands
      e = "codium .";
      c = "cd";

      # anti-prank prank
      vi = "loginctl lock-session #";
      vim = "loginctl lock-session #";
      nvim = "loginctl lock-session #";
    }
    // (outputs.nixosModules.packages args).environment.shellAliases;
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
    initContent = ''
      if [[ -r "$\{XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-$\{(%):-%n}.zsh" ]]; then
        source "$\{XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-$\{(%):-%n}.zsh"
      fi

      source ${./p10k.zsh}

      export PATH="$PATH:$HOME/.cargo/bin"
    '';

    oh-my-zsh = {
      enable = true;
      plugins = ["git"];
    };
  };
}
