# Plasma 6 Configuration with Wayland
{
  pkgs,
  lib,
  config,
  ...
}: {
  # ===
  # KDE
  # ===

  environment.variables = {
    KWIN_DRM_PREFER_COLOR_DEPTH = "24";
  };

  # Plasma repeatedly scans every entry in XDG_DATA_DIRS for QML resources.
  # Merge those entries into one symlink farm to avoid hundreds of thousands
  # of unsuccessful filesystem lookups.
  # https://github.com/NixOS/nixpkgs/issues/363068
  nixpkgs.overlays = [
    (final: prev: {
      kdePackages = prev.kdePackages.overrideScope (
        _kdeFinal: kdePrev: {
          plasma-workspace = let
            basePkg = kdePrev.plasma-workspace;
            xdgdataPkg = final.stdenv.mkDerivation {
              name = "${basePkg.name}-xdgdata";
              buildInputs = [basePkg];
              dontUnpack = true;
              dontFixup = true;
              dontWrapQtApps = true;
              installPhase = ''
                mkdir -p $out/share
                ( IFS=:
                  for DIR in $XDG_DATA_DIRS; do
                    if [[ -d "$DIR" ]]; then
                      ${final.lib.getExe final.lndir} -silent "$DIR" $out/share
                    fi
                  done
                )
              '';
            };
          in
            basePkg.overrideAttrs {
              preFixup = ''
                for index in "''${!qtWrapperArgs[@]}"; do
                  if [[ ''${qtWrapperArgs[$((index+0))]} == "--prefix" ]] && [[ ''${qtWrapperArgs[$((index+1))]} == "XDG_DATA_DIRS" ]]; then
                    unset -v "qtWrapperArgs[$((index+0))]"
                    unset -v "qtWrapperArgs[$((index+1))]"
                    unset -v "qtWrapperArgs[$((index+2))]"
                    unset -v "qtWrapperArgs[$((index+3))]"
                  fi
                done
                qtWrapperArgs=("''${qtWrapperArgs[@]}")
                qtWrapperArgs+=(--prefix XDG_DATA_DIRS : "${xdgdataPkg}/share")
                qtWrapperArgs+=(--prefix XDG_DATA_DIRS : "$out/share")
              '';
            };
        }
      );
    })
  ];

  # Enable the Plasma Desktop Environment.
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };
    defaultSession = "plasma";
  };
  services.desktopManager.plasma6.enable = true;

  # KDE Connect
  programs.kdeconnect.enable = true;
}
