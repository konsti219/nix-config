{
  config,
  lib,
  ...
}: {
  options.mainUser = lib.mkOption {
    type = lib.types.str;
    description = "Main user account, present on every host.";
  };

  config = {
    mainUser = "konsti";

    # Exported for the private flake, which composes the same hosts
    flake.mainUser = config.mainUser;
  };
}
