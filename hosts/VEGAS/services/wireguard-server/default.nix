{ config, ... }:
let
  inherit (config.networking) hostName;

  vpnNet = "10.100.0.0/24";
in
{
  age.secrets.wireguard-key-storm = {
    file = ../../../../secrets + "/wireguard-key-storm-${hostName}.age";
    mode = "0400";
  };

  networking = {
    firewall = {
      allowedUDPPorts = [ 123 ];
    };

    nat.internalIPs = [
      vpnNet
    ];

    wireguard = {
      enable = true;
      interfaces.wgstorm = {
        ips = [ "10.100.0.1/24" ];
        listenPort = 123;
        privateKeyFile = config.age.secrets.wireguard-key-storm.path;
        peers = [
          {
            publicKey = "1JzRMYmCDT9wqPT81u7VRF0KntThTGOsnSmYd0jovhQ=";
            allowedIPs = [ "10.100.0.4/32" ];
          }
          {
            publicKey = "7Bx5Agg2fHio2G3+ksI3osWkXBg5nP1bi06LjPafYG8=";
            allowedIPs = [ "10.100.0.13/32" ];
          }
          {
            publicKey = "GMVlOpvtIAmopM8W2bC6CzaK41/p3qLgq+/IgAjT8HY=";
            allowedIPs = [ "10.100.0.7/32" ];
          }
        ];
      };
    };
  };
}
