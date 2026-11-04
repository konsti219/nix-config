{
  flake.modules.homeManager.base = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.xdg) configHome dataHome stateHome cacheHome;
    # Recreated by programs that hardcode them and not worth keeping
    junk = [".java" ".dotnet" ".plastic4" ".pki"];
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
    };
    home.sessionPath = ["${dataHome}/cargo/bin"];

    xdg.configFile."wgetrc".text = "hsts-file = ${cacheHome}/wget-hsts\n";
    systemd.user.tmpfiles.rules = ["d ${stateHome}/python 0700 - - -"];

    systemd.user.services.home-junk-cleanup = {
      Unit.Description = "Remove dot dirs that programs recreate in $HOME";
      Service = {
        Type = "oneshot";
        ExecStart = toString (pkgs.writeShellScript "home-junk-cleanup" ''
          cd "$HOME" || exit 1
          ${pkgs.coreutils}/bin/rm -rf --one-file-system ${lib.escapeShellArgs junk}
          # .var also holds real flatpak app data once any app is installed
          if [ -z "$(${pkgs.coreutils}/bin/ls -A ${dataHome}/flatpak/app /var/lib/flatpak/app 2>/dev/null)" ]; then
            ${pkgs.coreutils}/bin/rm -rf --one-file-system .var
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
