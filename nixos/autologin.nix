{
  host,
  pkgs,
  ...
}: {
  services.displayManager.autoLogin = {
    enable = true;
    user = host.mainUser;
  };

  security.doas.package = pkgs.doas.overrideAttrs (oldAttrs: {
    postPatch =
      oldAttrs.postPatch
      + ''
        substituteInPlace pam.c shadow.c \
          --replace-fail "5 * 60" "30 * 60"
      '';
  });
}
