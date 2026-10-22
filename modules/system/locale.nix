{
  flake.modules.nixos.base =
    # Locale
    {...}: {
      # Set time zone.
      time.timeZone = "Europe/Berlin";

      # Wifi regulatory domain
      boot.extraModprobeConfig = ''
        options cfg80211 ieee80211_regdom="DE"
      '';

      # Select internationalisation properties.
      i18n.defaultLocale = "en_US.UTF-8";
      i18n.extraLocaleSettings = {
        LC_TIME = "de_DE.UTF-8";
      };
    };
}
