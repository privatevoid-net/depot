{ depot, lib, config, ... }:
let
  inherit (config.networking) hostName;
  hyprspaceCapableNodes = lib.filterAttrs (_: host: host.hyprspace.enable) depot.hours;
  peersFormatted = builtins.mapAttrs (name: x: {
    inherit name;
    inherit (x.hyprspace) id;
    routes = map (net: { inherit net; }) x.hyprspace.routes;
  }) hyprspaceCapableNodes;
  peersFiltered = lib.filterAttrs (name: _: name != hostName) peersFormatted;
  peerList = builtins.attrValues peersFiltered;
  myNode = config.reflection;
  listenPort = myNode.hyprspace.listenPort or 8001;

  privateKeyFile = config.age.secrets.hyprspace-key.path;
  nameservers = lib.unique config.networking.nameservers;

  additionalTCPPorts = [
    21
  ];
  additionalQUICPorts = [
    21
    443
    500
  ];
in {

  imports = [
    depot.inputs.hyprspace.nixosModules.default
  ];

  links.hyprspaceMetrics.protocol = "http";

  age.secrets.hyprspace-key = {
    file = ../../secrets/hyprspace-key- + "${hostName}.age";
    mode = "0400";
  };

  systemd.services.hyprspace = {
    serviceConfig = {
      IPAddressDeny = [
        "10.0.0.0/8"
        "100.64.0.0/10"
        "169.254.0.0/16"
        "172.16.0.0/12"
        "192.0.0.0/24"
        "192.0.2.0/24"
        "192.168.0.0/16"
        "198.18.0.0/15"
        "198.51.100.0/24"
        "203.0.113.0/24"
        "240.0.0.0/4"
        "100::/64"
        "2001:2::/48"
        "2001:db8::/32"
        "fc00::/7"
        "fe80::/10"
      ];
      IPAddressAllow = nameservers;
    };
  };

  services.hyprspace = {
    enable = true;
    metricsPort = config.links.hyprspaceMetrics.port;
    inherit privateKeyFile;
    settings = {
      listenAddresses = let
        inherit (myNode.interfaces.primary) addr;
        port = toString listenPort;
      in [
        "/ip4/${addr}/tcp/${port}"
        "/ip4/${addr}/udp/${port}/quic-v1"
      ]
      ++ (map (port: "/ip4/${addr}/tcp/${toString port}") additionalTCPPorts)
      ++ (map (port: "/ip4/${addr}/udp/${toString port}/quic-v1") additionalQUICPorts);
      peers = peerList;
    };
  };

  networking.firewall.trustedInterfaces = [ "hyprspace" ];

  services.alloy.metrics.targets.hyprspace = {
    address = config.links.hyprspaceMetrics.tuple;
    labels = {
      instance = hostName;
      peer_id = myNode.hyprspace.id;
    };
  };
}
