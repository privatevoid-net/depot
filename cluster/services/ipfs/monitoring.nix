{ config, cluster, lib, ... }:

let
  inherit (config) links;
in

{
  systemd.services.ipfs = {
    environment = {
      OTEL_TRACES_EXPORTER = "otlp";
      OTEL_EXPORTER_OTLP_PROTOCOL = "grpc";
      OTEL_EXPORTER_OTLP_ENDPOINT = "${cluster.config.ways.ingest-traces-otlp.url}:443";
      OTEL_TRACES_SAMPLER = "parentbased_traceidratio";
      OTEL_TRACES_SAMPLER_ARG = "0.50";
    };
  };

  services.alloy.metrics.targets.ipfs = {
    address = links.ipfsMetrics.tuple;
    metricsPath = links.ipfsMetrics.path;
    labels.instance = config.networking.hostName;
  };
}
