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
    prometheus-ingest = {
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
      logging = [ "VEGAS" "grail" ];
      tracing = [ "VEGAS" "grail" ];
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
      tracing = ./tracing.nix;
      server = [
        ./server.nix
      ];
    };
    meshLinks = {
      logging.loki.link.protocol = "http";
      tracing = {
        tempo.link.protocol = "http";
        tempo-otlp-http.link.protocol = "http";
        tempo-otlp-grpc.link.protocol = "grpc";
        tempo-zipkin-http.link.protocol = "http";
      };
    };
  };

  garage = config.lib.forService "monitoring" {
    keys = {
      loki-ingest.locksmith = {
        nodes = config.services.monitoring.nodes.logging;
        format = "envFile";
      };
      loki-query.locksmith = {
        nodes = config.services.monitoring.nodes.logging;
        format = "envFile";
      };
      tempo-ingest.locksmith = {
        nodes = config.services.monitoring.nodes.tracing;
        format = "envFile";
      };
      tempo-query.locksmith = {
        nodes = config.services.monitoring.nodes.tracing;
        format = "envFile";
      };
    };
    buckets = {
      loki-chunks.allow = {
        loki-ingest = [ "read" "write" ];
        loki-query = [ "read" ];
      };
      tempo-chunks.allow = {
        tempo-ingest = [ "read" "write" ];
        tempo-query = [ "read" ];
      };
    };
  };

  ways = let
    query = consulService: {
      inherit consulService;
      internal = true;
      extras.extraConfig = ''
        proxy_read_timeout 3600s;
      '';
    };
    ingest = consulService: {
      inherit consulService;
      internal = true;
      extras.extraConfig = ''
        client_max_body_size 4G;
        proxy_read_timeout 3600s;
      '';
    };
  in config.lib.forService "monitoring" {
    monitoring = {
      consulService = "grafana";
      extras.locations."/".proxyWebsockets = true;
    };
    monitoring-logs = query "loki";
    monitoring-traces = query "tempo";
    ingest-logs = ingest "loki";
    ingest-traces-otlp = ingest "tempo-ingest-otlp-grpc" // { grpc = true; };
  };
}
