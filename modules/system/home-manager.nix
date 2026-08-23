{
  config,
  inputs,
  ...
}: let
  inherit (config) mainUser;
in {
  flake.modules.nixos.base = {pkgs, ...}: {
    imports = [
      inputs.home-manager.nixosModules.home-manager
    ];

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "backup";

    # Define main user account
    users.users.${mainUser} = {
      isNormalUser = true;
      extraGroups = ["networkmanager" "wheel" "wireshark"];
      shell = pkgs.zsh;
    };
    # required here because shell is set to zsh
    programs.zsh.enable = true;
  };
}
