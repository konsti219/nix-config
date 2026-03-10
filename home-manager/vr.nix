{pkgs, lib, inputs, config, host, ...}: {
  xdg = {
    # https://lvra.gitlab.io/docs/distros/nixos/#runtimes
    configFile."openxr/1/active_runtime.json".source = "${pkgs.unstable.wivrn}/share/openxr/1/openxr_wivrn.json";

    # https://github.com/wlx-team/wayvr/wiki/Customization
    configFile."wayvr" = {
      source = ./wayvr;
      recursive = true;
      force = true;
    };

    configFile."openvr/openvrpaths.vrpath".text = let
      steam = "${config.xdg.dataHome}/Steam";
    in builtins.toJSON {
      version = 1;
      jsonid = "vrpathreg";

      external_drivers = null;
      config = [ "${steam}/config" ];

      log = [ "${steam}/logs" ];

      runtime = [
        # "${pkgs.xrizer}/lib/xrizer"
        # OR
        "${pkgs.unstable.opencomposite}/lib/opencomposite"
      ];
    };
  };
}