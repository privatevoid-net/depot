{ config, ... }:

{
  networking.firewall.allowedUDPPorts = [
    config.networking.wireguard.interfaces.wgautobahn.listenPort
  ];

  age.secrets.wireguard-key-wgautobahn = {
    file = ../../../../secrets/wireguard-key-wgautobahn.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
  age.secrets.wireguard-key-wgmv = {
    file = ../../../../secrets/wireguard-key-wgmv.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  networking.wireguard = {
    enable = true;
    interfaces.wgautobahn = {
      ips = [ "10.15.0.1/30" ];
      listenPort = 51820;
      privateKeyFile = config.age.secrets.wireguard-key-wgautobahn.path;

      allowedIPsAsRoutes = true;
      peers = [
        # animus
        {
          publicKey = "CIJ8W5SDMyPnSZLN2CNplwhGaNPUGoLV0mdzoDHhxUo=";
          allowedIPs = [ "10.15.0.0/30" "10.150.0.0/16" ];
          endpoint = "116.202.226.86:53042";
        }
      ];
    };
    interfaces.wgmv-es7 = {
      ips = [ "10.66.207.76/32" ];
      privateKeyFile = config.age.secrets.wireguard-key-wgmv.path;
      allowedIPsAsRoutes = false;
      peers = [
        # es7-wireguard
        {
          publicKey = "azJb0GofbDjSh2KTPReEeVdB8QVs4QC7E57P7MC7dQg=";
          allowedIPs = [ "10.64.0.1/32" "0.0.0.0/0" ];
          endpoint = "45.134.213.207:51820";
        }
      ];
    };
  };
  networking.interfaces = {
    wgmv-es7.ipv4.routes = [
      { address = "10.64.0.1"; prefixLength = 32; }
      { address = "10.124.0.0"; prefixLength = 16; }
    ];
  };
}
