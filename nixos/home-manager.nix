{ pkgs, inputs, outputs, host, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.${host.mainUser} = outputs.homeManagerModules.home;

  home-manager.extraSpecialArgs = { inherit inputs outputs host; };

  # Define main user account
  users.users.${host.mainUser} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  # Define guest account
  users.users.guest = {
    isNormalUser = true;
  };
}

