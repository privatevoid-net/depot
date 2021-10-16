{ config, hosts, lib, pkgs, tools, ... }:
let
  inherit (hosts.${config.networking.hostName}) interfaces;
  inherit (interfaces) vstub;
  inherit (config.networking) hostName;

  sharedConfig = pkgs.writeText "openvpn-shared.conf" ''
    port 51194
    float
    mssfix 1340

    topology subnet
    client-to-client
    persist-key
    persist-tun

    # vpn supernet
    push "route 10.100.0.0 255.255.0.0"
    # internal services supernet
    push "route 10.10.0.0 255.255.0.0"
    # host machine virtual stub
    push "route ${vstub.addr} 255.255.255.255"

    # dns config
    push "dhcp-option DOMAIN vpn.${tools.meta.domain}"
    push "dhcp-option DNS ${vstub.addr}"

    ca ${../../../../data/vpn-ca-bundle.crt}
    cert ${../../../../data + "/vpn-host-${hostName}.crt"}
    key ${config.age.secrets.vpn-host-key.path}
    dh ${config.security.dhparams.params.vpn.path}
  '';
in
{
  age.secrets.vpn-host-key = {
    file = ../../../../secrets + "/vpn-host-key-${hostName}.age";
    mode = "0400";
  };
  security.dhparams.params.vpn.bits = 4096;
  networking.firewall = {
    allowedTCPPorts = [ 51194 ];
    allowedUDPPorts = [ 51194 ];
  };
  networking.nat.internalInterfaces = [
    "tun-storm"
    "tun-cyclone"
  ];

  services.openvpn.servers = {
    storm = {
      autoStart = true;
      config = ''
        proto udp4
        dev tun-storm
        server 10.100.0.0 255.255.255.0
        config ${sharedConfig}
      '';
    };
    cyclone = {
      autoStart = true;
      config = ''
        proto tcp4
        dev tun-cyclone
        server 10.100.1.0 255.255.255.0
        config ${sharedConfig}
      '';
    };
  };
  systemd.services = lib.genAttrs (map (x: "openvpn-${x}") (builtins.attrNames config.services.openvpn.servers)) (_: {
    wants = [ "dhparams-gen-vpn.service" ];
    after = [ "dhparams-gen-vpn.service" ];
  });
}
