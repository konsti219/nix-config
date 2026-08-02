# Vesktop with the DiscordMuteBridge userplugin, which registers voice-mute
# shortcuts with xdg-desktop-portal's GlobalShortcuts API
# Vesktop for screen share audio
{
  pkgs,
  lib,
  ...
}: let
  upkgs = pkgs.unstable;

  # Vendor the node module directly, is easier to maintain
  vendoredNodeModules = {
    dbus-native = pkgs.fetchzip {
      name = "dbus-native-0.15.1";
      url = "https://registry.npmjs.org/dbus-native/-/dbus-native-0.15.1.tgz";
      hash = "sha256-bFW5T3WjAqAIgC8ccFsfeuYbHk/uTKGMMTYfsb5xsjM=";
    };
    xml2js = ./mute-bridge/xml2js-stub;
  };

  # Inject in preBuild, not postPatch: pnpmDeps inherits postPatch, and preBuild
  # runs after `pnpm install`, so neither the plugin nor the vendored modules
  # are visible to the pinned pnpm hash.
  vencordWithBridge = upkgs.vencord.overrideAttrs (old: {
    preBuild =
      (old.preBuild or "")
      + ''
        mkdir -p src/userplugins/discordMuteBridge
        cp ${./mute-bridge/index.ts} src/userplugins/discordMuteBridge/index.ts
        cp ${./mute-bridge/native.ts} src/userplugins/discordMuteBridge/native.ts
        cp ${./mute-bridge/portal.ts} src/userplugins/discordMuteBridge/portal.ts
      ''
      + lib.concatStringsSep "\n" (lib.mapAttrsToList (name: src: ''
          mkdir -p node_modules/${name}
          cp -r --no-preserve=mode,ownership ${src}/. node_modules/${name}/
        '')
        vendoredNodeModules);
  });

  # use vencord from nixpkgs isntead of bundled
  vesktopBase = upkgs.vesktop.override {
    withSystemVencord = true;
    vencord = vencordWithBridge;
  };

  # Auto-select the screenshare audio source from the window picked in the
  # portal; see auto-audio/autoPickAudio.ts for how the window is identified.
  # Applied in postPatch rather than `patches` because vesktop's fetchPnpmDeps
  # inherits `patches`, and touching it would invalidate the pinned pnpm hash.
  vesktopWithBridge = vesktopBase.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        patch -p1 < ${./auto-audio/vesktop-auto-audio.patch}
        cp ${./auto-audio/autoPickAudio.ts} src/main/autoPickAudio.ts
        substituteInPlace src/main/autoPickAudio.ts \
          --replace-fail '@PW_DUMP@' '${upkgs.pipewire}/bin/pw-dump'
      '';
  });
in {
  home.packages = [
    vesktopWithBridge
  ];
}
