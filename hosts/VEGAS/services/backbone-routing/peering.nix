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
    interfaces.wgmv-es1 = {
      ips = [ "10.65.193.152/32" ];
      privateKeyFile = config.age.secrets.wireguard-key-wgmv.path;
      allowedIPsAsRoutes = false;
      peers = [
        # es1-wireguard
        {
          publicKey = "hDflDse0Nz7GsZ0q5uylWOJaJQ6woJPCGy8IvTXKjzo=";
          allowedIPs = [ "10.64.0.1/32" "0.0.0.0/0" ];
          endpoint = "194.99.104.10:51820";
        }
      ];
    };
  };
  networking.interfaces = {
    wgmv-es1.ipv4.routes = [
      { address = "10.64.0.1"; prefixLength = 32; }
      { address = "10.124.0.0"; prefixLength = 16; }
    ];
  };
}
