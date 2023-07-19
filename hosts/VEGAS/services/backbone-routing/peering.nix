{ config, ... }:

{
  age.secrets.wireguard-key-wgmv = {
    file = ../../../../secrets/wireguard-key-wgmv.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  networking.wireguard = {
    enable = true;
    interfaces.wgmv = {
      ips = [ "10.65.193.152/32" ];
      privateKeyFile = config.age.secrets.wireguard-key-wgmv.path;
      allowedIPsAsRoutes = false;
      peers = [
        # es-mad-wg-102
        {
          publicKey = "1Wo/cQeVHX2q9k95nxN+48lgkGLsPQ+uesRb/9XdY1Y=";
          allowedIPs = [ "10.64.0.1/32" "0.0.0.0/0" ];
          endpoint = "45.134.213.207:51820";
        }
        # es-mad-wg-202
        {
          publicKey = "iehXacO91FbBqni2IFxedEYPlW2Wvvt9GtRPPPMo9zc=";
          allowedIPs = [ "10.64.0.1/32" "0.0.0.0/0" ];
          endpoint = "146.70.128.226:51820";
        }
      ];
    };
  };
  networking.interfaces = {
    wgmv.ipv4.routes = [
      { address = "10.64.0.1"; prefixLength = 32; }
      { address = "10.124.0.0"; prefixLength = 16; }
    ];
  };
}
