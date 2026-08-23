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
  powerManagement.cpuFreqGovernor = "performance";
  hardware.enableRedistributableFirmware = true;
}
