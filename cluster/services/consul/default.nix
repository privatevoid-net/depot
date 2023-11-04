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
    nodes.agent = [ "checkmate" "grail" "thunderskin" "VEGAS" "prophet" ];
    nixos.agent = [
      ./agent.nix
      ./remote-api.nix
    ];
  };

  dns.records."consul-remote.internal".consulService = "consul-remote";
}
