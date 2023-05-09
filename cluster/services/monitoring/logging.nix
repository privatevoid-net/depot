{ config, cluster, ... }:

let
  inherit (config.links) loki-grpc;

  inherit (cluster.config.links) loki-ingest;

  cfg = config.services.loki;
in
{
  links.loki-grpc.protocol = "grpc";
  systemd.services.loki.after = [ "wireguard-wgmesh.service" ];
  services.loki = {
    enable = true;
    dataDir = "/srv/storage/private/loki";
    configuration = {
      auth_enabled = false;
      server = {
        log_level = "warn";
        http_listen_address = loki-ingest.ipv4;
        http_listen_port = loki-ingest.port;
        grpc_listen_address = loki-grpc.ipv4;
        grpc_listen_port = loki-grpc.port;
      };
      frontend_worker.frontend_address = loki-grpc.tuple;
      ingester = {
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore.store = "inmemory";
            replication_factor = 1;
          };
          final_sleep = "0s";
        };
        chunk_idle_period = "5m";
        chunk_retain_period = "30s";
      };
      schema_config.configs = [
        {
          from = "2022-05-14";
          store = "boltdb";
          object_store = "filesystem";
          schema = "v11";
          index = {
            prefix = "index_";
            period = "168h";
          };
        }
      ];
      storage_config = {
        boltdb.directory = "${cfg.dataDir}/boltdb-index";
        filesystem.directory = "${cfg.dataDir}/storage-chunks";
      };
      limits_config = {
        enforce_metric_name = false;
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
      };
    };
  };
}
