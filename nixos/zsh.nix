# Configure zsh
{ pkgs, ... }: {
  programs.zsh = {
    enable = true;
    shellAliases = {
      vi = "loginctl lock-session #";
      vim = "loginctl lock-session #";
      nvim = "loginctl lock-session #";
    };
    histSize = 16384;
    histFile = "~/zsh/history";
    autosuggestions.enable = true;

    promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";

    ohMyZsh = {
      enable = true;
      plugins = [ "git" "thefuck" ];
    };
  };
  environment.systemPackages = with pkgs; [ thefuck ];
}
