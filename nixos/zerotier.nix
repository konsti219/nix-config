# Enable Zertier and join personal network.
{ ... }: {
  services.zerotierone.enable = true;
  services.zerotierone.joinNetworks = [ "60ee7c034a89a4ea" ];
}

