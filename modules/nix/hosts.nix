{
  config,
  lib,
  ...
}: {
  options.hosts = lib.mkOption {
    default = {};
    description = "Every machine this config knows about.";
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        platform = lib.mkOption {
          type = lib.types.str;
          default = "x86_64-linux";
        };
      };
    });
  };

  # Exported so the private flake can build the same set of hosts
  config.flake.hosts = config.hosts;
}
