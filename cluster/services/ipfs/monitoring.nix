{ cluster, ... }:

{
  systemd.services.ipfs = {
    environment = {
      OTEL_TRACES_EXPORTER = "otlp";
      OTEL_EXPORTER_OTLP_PROTOCOL = "grpc";
      OTEL_EXPORTER_OTLP_ENDPOINT = cluster.config.links.tempo-otlp-grpc.url;
      OTEL_TRACES_SAMPLER = "parentbased_traceidratio";
      OTEL_TRACES_SAMPLER_ARG = "0.50";
    };
  };
}
