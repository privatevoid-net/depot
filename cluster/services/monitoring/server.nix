{ cluster, ... }:
let
  inherit (cluster.config.links) prometheus-ingest;
in
{
  services.prometheus = {
    enable = true;
    listenAddress = prometheus-ingest.ipv4;
    inherit (prometheus-ingest) port;
    extraFlags = [ "--web.enable-remote-write-receiver" ];
    globalConfig = {
      scrape_interval = "60s";
    };
    scrapeConfigs = [ ];
  };

}
