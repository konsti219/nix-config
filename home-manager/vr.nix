{pkgs, lib, inputs, ...}: {
  xdg = {
    # https://lvra.gitlab.io/docs/distros/nixos/#runtimes
    configFile."openxr/1/active_runtime.json" = {
      inherit (osConfig.environment.etc."xdg/openxr/1/active_runtime.json") source;
      force = true;
    };

    # https://github.com/wlx-team/wayvr/wiki/Customization
    configFile."wayvr" = {
      source = ./wayvr;
      recursive = true;
      force = true;
    };

    # https://lvra.gitlab.io/docs/fossvr/opencomposite/#rebinding-controls
    dataFile."Steam/steamapps/common/VRChat/OpenComposite/oculus_touch.json" = {
      source = ./opencomposite/vrchat/oculus_touch.json;
    };
  };

  # TODO temporary workaround until https://www.github.com/hyprwm/xdg-desktop-portal-hyprland/issues/329 is implemented properly
  wayland.windowManager.hyprland.xdgDesktopPortalHyprland.settings = {
    screencopy = {
      custom_picker_binary = lib.getExe (
        pkgs.writeShellApplication {
          name = "hyprland-share-picker-xr";
          runtimeInputs = [ osConfig.programs.hyprland.portalPackage ];
          text = lib.readFile ./hyprland-share-picker-xr.sh;
        }
      );
    };
  };
}