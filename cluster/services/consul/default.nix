{ config, lib, ... }:

let
  cfg = config.services.consul;
in

{
  hostLinks = lib.genAttrs cfg.nodes.agent (hostName: {
    consul = {
      ipv4 = config.vars.mesh.${hostName}.meshIp;
    };
  });
  services.consul = {
    nodes = {
      agent = [ "checkmate" "grail" "thunderskin" "VEGAS" "prophet" "thousandman" ];
      ready = config.services.consul.nodes.agent;
    };
    nixos = {
      agent = [
        ./agent.nix
        ./remote-api.nix
      ];
      ready = ./ready.nix;
    };
    simulacrum = {
      enable = true;
      deps = [ "wireguard" ];
      settings = ./test.nix;
    };
  };

  dns.records."consul-remote.internal".consulService = "consul-remote";
}
