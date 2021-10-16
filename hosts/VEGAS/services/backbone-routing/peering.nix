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
  };
}
