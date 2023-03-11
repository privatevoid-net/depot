{ config, depot, lib, tools, ... }:

{
  hostLinks = lib.genAttrs config.services.ipfs.nodes.node (name: let
    host = depot.reflection;
    intf = host.interfaces.primary;
    self = config.hostLinks.${name}.ipfs;
  in {
    ipfs = {
      ipv4 = if intf ? addrPublic then intf.addrPublic  else intf.addr;
      port = 4001;
      extra = {
        peerId = {
          VEGAS = "Qmd7QHZU8UjfYdwmjmq1SBh9pvER9AwHpfwQvnvNo3HBBo";
          prophet = "12D3KooWQWsHPUUeFhe4b6pyCaD1hBoj8j6Z7S7kTznRTh1p1eVt";
        }.${name};
        multiaddrs = [
          "/ip4/${self.ipv4}/udp/${self.portStr}/quic"
          "/ip4/${self.ipv4}/tcp/${self.portStr}"
        ];
      };
    };
  });
  services.ipfs = {
    nodes = {
      node = [ "VEGAS" "prophet" ];
      clusterPeer = [ "VEGAS" "prophet" ];
      gateway = [ "VEGAS" ];
    };
    nixos = {
      node = [
        ./node.nix
      ];
      gateway = [
        ./gateway.nix
        ./monitoring.nix
      ];
      clusterPeer = [
        ./cluster.nix
      ];
    };
  };
}
