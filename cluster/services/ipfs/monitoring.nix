{ config, cluster, lib, ... }:

let
  inherit (config) links;
in

{
  systemd.services.ipfs = {
    environment = {
      OTEL_TRACES_EXPORTER = "otlp";
      OTEL_EXPORTER_OTLP_PROTOCOL = "grpc";
      OTEL_EXPORTER_OTLP_ENDPOINT = cluster.config.ways.ingest-traces-otlp.url;
      OTEL_TRACES_SAMPLER = "parentbased_traceidratio";
      OTEL_TRACES_SAMPLER_ARG = "0.50";
    };
  };

  services.grafana-agent.settings.metrics.configs = lib.singleton {
    name = "metrics-ipfs";
    scrape_configs = lib.singleton {
      job_name = "ipfs";
      metrics_path = links.ipfsMetrics.path;
      static_configs = lib.singleton {
        targets = lib.singleton links.ipfsMetrics.tuple;
        labels.instance = config.networking.hostName;
      };
    };
  };
}
