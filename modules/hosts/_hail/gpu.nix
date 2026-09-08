{pkgs, ...}: {
  hardware.amdgpu.overdrive.enable = true;
  services.lact.enable = true;
  services.lact.package = pkgs.unstable.lact;
  environment.systemPackages = [pkgs.unstable.lact];
  environment.sessionVariables = {
    # Force high-performance geometry (NGG)
    RADV_PERFTEST = "ngg,rt";
    # Enable Variable Rate Shading for more FPS
    RADV_FORCE_VRS = "2x2";
  };
  # Work around DCC metadata corruption painting 8x4 garbage blocks into the wallpaper
  systemd.user.services.plasma-plasmashell = {
    overrideStrategy = "asDropin";
    environment.AMD_DEBUG = "nodcc";
  };
  nixpkgs.overlays = [
    (_final: prev: {
      btop = prev.btop.override {rocmSupport = true;};
    })
  ];
  powerManagement.cpuFreqGovernor = "performance";
  hardware.enableRedistributableFirmware = true;
}
