{
  config,
  lib,
  ...
}: {
  options.hosts = lib.mkOption {
    default = {};
    description = "Every machine this config knows about.";
    type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
      options = {
        hostName = lib.mkOption {
          type = lib.types.str;
          default = name;
        };

        platform = lib.mkOption {
          type = lib.types.str;
          default = "x86_64-linux";
        };

        nixos = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to build a NixOS system, not just a home-manager one.";
        };
      };
    }));
  };

  # Exported so the private flake can build the same set of hosts
  config.flake.hosts = config.hosts;
}
