{ config, ... }:

let
  nodeFor = nodeType: builtins.head config.services.monitoring.nodes.${nodeType};

  meshIpFor = nodeType: config.vars.mesh.${nodeFor nodeType}.meshIp;
in

{
  links = {
    loki-ingest = {
      protocol = "http";
      ipv4 = meshIpFor "logging";
    };
    loki = {
      protocol = "http";
      ipv4 = meshIpFor "logging";
    };
  };
  services.monitoring = {
    nodes = {
      client = [ "checkmate" "thunderskin" "VEGAS" "prophet" ];
      logging = [ "VEGAS" ];
      server = [ "VEGAS" ];
    };
    nixos = {
      client = ./client.nix;
      logging = ./logging.nix;
      server = [
        ./server.nix
        ./tracing.nix
      ];
    };
  };
}
