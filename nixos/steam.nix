# Steam config
{...}: {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };
  hardware.graphics.enable32Bit = true; # Enables support for 32bit libs that steam uses
}
