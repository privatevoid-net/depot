{ cluster, config, pkgs, ... }:

let
  inherit (cluster.config.links) prometheus-ingest;
  inherit (config.links) tempo-grpc;
  links = cluster.config.hostLinks.${config.networking.hostName};
  dataDir = "/srv/storage/private/tempo";
  tempoConfig = {
    server = {
      http_listen_address = links.tempo.ipv4;
      http_listen_port = links.tempo.port;
      grpc_listen_address = tempo-grpc.ipv4;
      grpc_listen_port = tempo-grpc.port;
    };
    distributor.receivers = {
      otlp = {
        protocols = {
          http.endpoint = links.tempo-otlp-http.tuple;
          grpc.endpoint = links.tempo-otlp-grpc.tuple;
        };
      };
      zipkin.endpoint = links.tempo-zipkin-http.tuple;
    };
    querier.frontend_worker.frontend_address = tempo-grpc.tuple;
    ingester = {
      trace_idle_period = "30s";
      max_block_bytes = 1000000;
      max_block_duration = "5m";
    };
    compactor = {
      compaction = {
        compaction_window = "1h";
        max_block_bytes = 100000000;
        compacted_block_retention = "10m";
      };
    };
    storage.trace = {
      backend = "s3";
      block.bloom_filter_false_positive = 0.05;
      wal.path = "${dataDir}/wal";
      s3 = {
        bucket = "tempo-chunks";
        endpoint = cluster.config.links.garageS3.hostname;
        region = "us-east-1";
        forcepathstyle = true;
      };
      pool = {
        max_workers = 16;
        queue_depth = 1000;
      };
    };
    metrics_generator = {
      registry.external_labels = {
        source = "tempo";
        host = config.networking.hostName;
      };
      storage = {
        path = "${dataDir}/generator/wal";
        remote_write = [
          {
            url = "${prometheus-ingest.url}/api/v1/write";
            send_exemplars = true;
          }
        ];
      };
    };
    overrides.metrics_generator_processors = [
      "service-graphs"
      "span-metrics"
    ];
  };
in {
  links.tempo-grpc.protocol = "http";

  services.locksmith.waitForSecrets.tempo = [
    "garage-tempo-ingest"
  ];

  users.users.tempo = {
    isSystemUser = true;
    group = "tempo";
    home = dataDir;
    createHome = true;
  };

  users.groups.tempo = {};

  systemd.services.tempo = {
    wantedBy = [ "multi-user.target" ];
    distributed = {
      enable = true;
      registerServices = [
        "tempo"
        "tempo-ingest-otlp-grpc"
      ];
    };
    serviceConfig = {
      User = "tempo";
      Group = "tempo";
      ExecStart = "${pkgs.tempo}/bin/tempo -config.file=${pkgs.writeText "tempo.yaml" (builtins.toJSON tempoConfig)}";
      PrivateTmp = true;
      EnvironmentFile = "/run/locksmith/garage-tempo-ingest";
    };
  };

  consul.services = {
    tempo = {
      mode = "manual";
      definition = {
        name = "tempo";
        address = links.tempo.ipv4;
        inherit (links.tempo) port;
        checks = [
          {
            name = "Tempo";
            id = "service:tempo:backend";
            interval = "5s";
            http = "${links.tempo.url}/ready";
          }
        ];
      };
    };
    tempo-ingest-otlp-grpc = {
      mode = "manual";
      definition = {
        name = "tempo-ingest-otlp-grpc";
        address = links.tempo-otlp-grpc.ipv4;
        inherit (links.tempo-otlp-grpc) port;
        checks = [
          {
            name = "Tempo Service Status";
            id = "service:tempo-ingest-otlp-grpc:tempo";
            alias_service = "tempo";
          }
        ];
      };
    };
  };
}
