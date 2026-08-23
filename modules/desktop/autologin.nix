{config, ...}: let
  inherit (config) mainUser;
in {
  flake.modules.nixos.hail = {pkgs, ...}: {
    services.displayManager.autoLogin = {
      enable = true;
      user = mainUser;
    };

    security.doas.package = pkgs.doas.overrideAttrs (oldAttrs: {
      postPatch =
        oldAttrs.postPatch
        + ''
          substituteInPlace pam.c shadow.c \
            --replace-fail "5 * 60" "30 * 60"
        '';
    });
  };
}
