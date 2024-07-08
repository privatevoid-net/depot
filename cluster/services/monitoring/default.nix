{ config, lib, ... }:

let
  nodeFor = nodeType: builtins.head config.services.monitoring.nodes.${nodeType};

  meshIpFor = nodeType: config.vars.mesh.${nodeFor nodeType}.meshIp;

  meshIpForNode = name: config.vars.mesh.${name}.meshIp;
in

{
  imports = [
    ./options.nix
  ];

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
      ipv4 = "127.0.0.1";
    };
    tempo-otlp-http = {
      protocol = "http";
      ipv4 = meshIpFor "server";
    };
    tempo-otlp-grpc = {
      protocol = "http";
      ipv4 = meshIpFor "server";
    };
    tempo-zipkin-http = {
      protocol = "http";
      ipv4 = meshIpFor "server";
    };
  };
  hostLinks = lib.genAttrs config.services.monitoring.nodes.grafana (name: {
    grafana = {
      protocol = "http";
      ipv4 = meshIpForNode name;
    };
  });
  services.monitoring = {
    nodes = {
      client = [ "checkmate" "grail" "thunderskin" "VEGAS" "prophet" ];
      blackbox = [ "checkmate" "grail" "prophet" ];
      grafana = [ "VEGAS" "prophet" ];
      logging = [ "VEGAS" ];
      server = [ "VEGAS" ];
    };
    nixos = {
      client = ./client.nix;
      blackbox = ./blackbox.nix;
      grafana = [
        ./grafana-ha.nix
        ./provisioning/dashboards.nix
      ];
      logging = ./logging.nix;
      server = [
        ./server.nix
        ./tracing.nix
      ];
    };
  };

  garage = {
    keys = {
      loki = { };
      tempo = { };
    };
    buckets = {
      loki-chunks.allow.loki = [ "read" "write" ];
      tempo-chunks.allow.tempo = [ "read" "write" ];
    };
  };

  ways.monitoring = {
    consulService = "grafana";
    extras.locations."/".proxyWebsockets = true;
  };
}
