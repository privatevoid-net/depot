{ config, lib, ... }:

let
  inherit (config.links) garageMetrics;
in

{
  services.grafana-agent = {
    settings.metrics.configs = lib.singleton {
      name = "metrics-garage";
      scrape_configs = lib.singleton {
        job_name = "garage";
        static_configs = lib.singleton {
          targets = lib.singleton garageMetrics.tuple;
          labels.instance = config.networking.hostName;
        };
      };
    };
  };
}
