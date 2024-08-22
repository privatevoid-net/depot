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
      agent = [ "checkmate" "grail" "thunderskin" "VEGAS" "prophet" ];
      ready = config.services.consul.nodes.agent;
      bootstrap = [ "grail" "VEGAS" ];
    };
    nixos = {
      agent = [
        ./agent.nix
        ./remote-api.nix
      ];
      ready = ./ready.nix;
      bootstrap = ./bootstrap.nix;
    };
    simulacrum = {
      enable = true;
      deps = [ "wireguard" "locksmith" ];
      settings = ./test.nix;
    };
  };

  dns.records."consul-remote.internal".consulService = "consul-remote";
}
