{
  flake.modules.homeManager.base = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.xdg) configHome dataHome stateHome cacheHome;
    # Recreated by programs that hardcode them and not worth keeping
    junk = [".dotnet" ".plastic4" ".pki"];
  in {
    home.sessionVariables = {
      CARGO_HOME = "${dataHome}/cargo";
      RUSTUP_HOME = "${dataHome}/rustup";
      GRADLE_USER_HOME = "${dataHome}/gradle";
      ANDROID_USER_HOME = "${dataHome}/android";
      GNUPGHOME = "${dataHome}/gnupg";
      npm_config_cache = "${cacheHome}/npm";
      YARN_GLOBAL_FOLDER = "${dataHome}/yarn";
      MONO_REGISTRY_PATH = "${dataHome}/mono/registry";
      COPILOT_HOME = "${configHome}/copilot";
      PYTHON_HISTORY = "${stateHome}/python/history";
      WGETRC = "${configHome}/wgetrc";
      VSCODE_AGENT_FOLDER = "${dataHome}/vscode-server";
    };
    home.sessionPath = ["${dataHome}/cargo/bin"];

    xdg.configFile."wgetrc".text = "hsts-file = ${cacheHome}/wget-hsts\n";
    programs.bash.historyFile = "${stateHome}/bash/history";
    systemd.user.tmpfiles.rules = ["d ${stateHome}/python 0700 - - -" "d ${stateHome}/bash 0700 - - -"];

    systemd.user.services.home-junk-cleanup = {
      Unit.Description = "Remove dot dirs that programs recreate in $HOME";
      Service = {
        Type = "oneshot";
        ExecStart = toString (pkgs.writeShellScript "home-junk-cleanup" ''
          PATH=${lib.makeBinPath [pkgs.coreutils pkgs.findutils]}
          cd "$HOME" || exit 1
          rm -rf --one-file-system ${lib.escapeShellArgs junk}
          # Font cache
          [ -e .java/.userPrefs ] || rm -rf --one-file-system .java
          if [ -d .var ] && [ -z "$(find .var -type f ! -name plasma-browser-integration-host ! -name org.kde.plasma.browser_integration.json)" ]; then
            rm -rf --one-file-system .var
          fi
        '');
      };
    };
    systemd.user.timers.home-junk-cleanup = {
      Unit.Description = "Remove dot dirs that programs recreate in $HOME";
      Timer = {
        OnStartupSec = "5min";
        OnCalendar = "daily";
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
