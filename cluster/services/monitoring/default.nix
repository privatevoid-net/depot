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
      logging = [ "VEGAS" "grail" ];
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
    meshLinks.logging = {
      name = "loki";
      link.protocol = "http";
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
      tempo = { };
    };
    buckets = {
      loki-chunks.allow = {
        loki-ingest = [ "read" "write" ];
        loki-query = [ "read" ];
      };
      tempo-chunks.allow.tempo = [ "read" "write" ];
    };
  };

  ways = {
    monitoring = {
      consulService = "grafana";
      extras.locations."/".proxyWebsockets = true;
    };
    monitoring-logs = {
      internal = true;
      consulService = "loki";
      extras.extraConfig = ''
        client_max_body_size 4G;
        proxy_read_timeout 3600s;
      '';
    };
  };
}
