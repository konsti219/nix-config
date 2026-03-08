{...}: {
  environment.systemPackages = with pkgs.unstable; [
    vrcx
  ];
}
