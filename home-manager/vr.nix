{
  pkgs,
  lib,
  inputs,
  config,
  host,
  ...
}: {
  xdg = {
    configFile."wayvr" = {
      source = ./wayvr;
      recursive = true;
      force = true;
    };

    configFile."openvr/openvrpaths.vrpath" = {
      force = true;
      text = let
        steam = "${config.xdg.dataHome}/Steam";
      in
        builtins.toJSON {
          version = 1;
          jsonid = "vrpathreg";

          external_drivers = null;
          config = ["${steam}/config"];

          log = ["${steam}/logs"];

          runtime = [
            "${pkgs.unstable.xrizer}/lib/xrizer"
          ];
        };
    };
  };
}
