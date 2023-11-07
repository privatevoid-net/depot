{ config, cluster, ... }:

let
  inherit (config.links) loki-grpc;

  inherit (cluster.config.links) loki-ingest;

  cfg = config.services.loki;
in
{
  age.secrets.lokiSecrets.file = ./secrets/loki-secrets.age;
  links.loki-grpc.protocol = "grpc";
  systemd.services.loki = {
    after = [ "wireguard-wgmesh.service" ];
    serviceConfig.EnvironmentFile = config.age.secrets.lokiSecrets.path;
  };
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
        {
          from = "2023-11-08";
          store = "boltdb-shipper";
          object_store = "s3";
          schema = "v11";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
      storage_config = {
        boltdb.directory = "${cfg.dataDir}/boltdb-index";
        filesystem.directory = "${cfg.dataDir}/storage-chunks";
        boltdb_shipper = {
          shared_store = "s3";
          active_index_directory = "${cfg.dataDir}/boltdb-shipper-index";
          cache_location = "${cfg.dataDir}/boltdb-shipper-cache";
        };
        aws = {
          endpoint = cluster.config.links.garageS3.url;
          s3forcepathstyle = true;
          bucketnames = "loki-chunks";
          region = "us-east-1";
          access_key_id = "\${AWS_ACCESS_KEY_ID}";
          secret_access_key = "\${AWS_SECRET_ACCESS_KEY}";
        };
      };
      compactor = {
        shared_store = "s3";
        working_directory = "${cfg.dataDir}/compactor-work";
      };
      limits_config = {
        enforce_metric_name = false;
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
      };
    };
  };
}
