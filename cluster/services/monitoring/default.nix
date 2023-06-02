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
    prometheus-ingest = {
      protocol = "http";
      ipv4 = meshIpFor "server";
    };
    tempo = {
      protocol = "http";
      ipv4 = meshIpFor "server";
    };
    tempo-grpc = {
      protocol = "http";
      ipv4 = meshIpFor "server";
    };
    tempo-otlp-http = {
      protocol = "http";
      ipv4 = meshIpFor "server";
    };
    tempo-otlp-grpc = {
      protocol = "http";
      ipv4 = meshIpFor "server";
    };
  };
  services.monitoring = {
    nodes = {
      client = [ "checkmate" "thunderskin" "VEGAS" "prophet" ];
      blackbox = [ "checkmate" "VEGAS" "prophet" ];
      logging = [ "VEGAS" ];
      server = [ "VEGAS" ];
    };
    nixos = {
      client = ./client.nix;
      blackbox = ./blackbox.nix;
      logging = ./logging.nix;
      server = [
        ./server.nix
        ./tracing.nix
        ./provisioning/dashboards.nix
      ];
    };
  };
}
