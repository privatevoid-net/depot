{ config, cluster, ... }:

let
  inherit (config.links) loki-grpc;

  link = cluster.config.hostLinks.${config.networking.hostName}.loki;

  cfg = config.services.loki;
in
{
  links.loki-grpc.protocol = "grpc";
  systemd.services.loki = {
    distributed = {
      enable = true;
      registerService = "loki";
    };
    after = [ "wireguard-wgmesh.service" ];
    serviceConfig.EnvironmentFile = "/run/locksmith/garage-loki-ingest";
  };

  services.locksmith.waitForSecrets.loki = [
    "garage-loki-ingest"
  ];

  services.loki = {
    enable = true;
    dataDir = "/srv/storage/private/loki";
    extraFlags = [ "--config.expand-env=true" ];
    configuration = {
      auth_enabled = false;
      server = {
        log_level = "warn";
        http_listen_address = link.ipv4;
        http_listen_port = link.port;
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
        {
          from = "2024-06-10";
          store = "tsdb";
          object_store = "s3";
          schema = "v13";
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
          active_index_directory = "${cfg.dataDir}/boltdb-shipper-index";
          cache_location = "${cfg.dataDir}/boltdb-shipper-cache";
        };
        tsdb_shipper = {
          active_index_directory = "${cfg.dataDir}/tsdb-shipper-index";
          cache_location = "${cfg.dataDir}/tsdb-shipper-cache";
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
        working_directory = "${cfg.dataDir}/compactor-work";
      };
      limits_config = {
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
        allow_structured_metadata = false;
      };
      query_scheduler.max_outstanding_requests_per_tenant = 32768;
      querier.max_concurrent = 16;
    };
  };

  consul.services.loki = {
    mode = "manual";
    definition = {
      name = "loki";
      address = link.ipv4;
      inherit (link) port;
      checks = [
        {
          name = "Loki";
          id = "service:loki:backend";
          interval = "5s";
          http = "${link.url}/ready";
        }
      ];
    };
  };
}
