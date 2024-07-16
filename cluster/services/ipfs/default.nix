{ config, depot, lib, ... }:

{
  hostLinks = lib.genAttrs config.services.ipfs.nodes.node (name: let
    host = depot.hours.${name};
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
          "/ip4/${self.ipv4}/udp/${self.portStr}/quic-v1"
          "/ip4/${self.ipv4}/tcp/${self.portStr}"
        ];
      };
    };
  });
  services.ipfs = {
    nodes = {
      node = [ "VEGAS" "prophet" ];
      clusterPeer = [ "VEGAS" "prophet" ];
      gateway = [ "VEGAS" "prophet" ];
      io-tweaks = [ "VEGAS" ];
      remote-api = [ "VEGAS" ];
    };
    meshLinks.gateway = {
      name = "ipfsGateway";
      link.protocol = "http";
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
      io-tweaks = ./io-tweaks.nix;
      remote-api = ./remote-api.nix;
    };
    secrets = let
      inherit (config.services.ipfs) nodes;
    in {
      clusterSecret = {
        nodes = nodes.clusterPeer;
      };
      pinningServiceCredentials = {
        nodes = nodes.clusterPeer;
        owner = "ipfs";
      };
    };
  };

  monitoring.blackbox.targets.ipfs-gateway = {
    address = "https://bafybeiczsscdsbs7ffqz55asqdf3smv6klcw3gofszvwlyarci47bgf354.ipfs.${depot.lib.meta.domain}/";
    module = "https2xx";
  };

  dns.records = {
    "ipfs.admin".target = map
      (node: depot.hours.${node}.interfaces.primary.addrPublic)
      config.services.ipfs.nodes.remote-api;
    pin.consulService = "ipfs-gateway";
  };

  ways = {
    p2p = {
      consulService = "ipfs-gateway";
      extras.locations."/" = {
        extraConfig = ''
          add_header X-Content-Type-Options "";
          add_header Access-Control-Allow-Origin *;
        '';
      };
    };
    ipfs = {
      consulService = "ipfs-gateway";
      wildcard = true;
      extras.extraConfig = ''
        add_header X-Content-Type-Options "";
        add_header Access-Control-Allow-Origin *;
      '';
    };
    ipns = {
      consulService = "ipfs-gateway";
      wildcard = true;
      extras.extraConfig = ''
        add_header X-Content-Type-Options "";
        add_header Access-Control-Allow-Origin *;
      '';
    };
  };
}
