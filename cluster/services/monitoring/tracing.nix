{ cluster, config, pkgs, ... }:

let
  inherit (cluster.config) links;
  dataDir = "/srv/storage/private/tempo";
  tempoConfig = {
    server = {
      http_listen_address = links.tempo.ipv4;
      http_listen_port = links.tempo.port;
      grpc_listen_address = links.tempo-grpc.ipv4;
      grpc_listen_port = links.tempo-grpc.port;
    };
    distributor.receivers.otlp = {
      protocols = {
        http.endpoint = links.tempo-otlp-http.tuple;
        grpc.endpoint = links.tempo-otlp-grpc.tuple;
      };
    };
    querier.frontend_worker.frontend_address = links.tempo-grpc.tuple;
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
      backend = "local";
      block.bloom_filter_false_positive = 0.05;
      wal.path = "${dataDir}/wal";
      local.path = "${dataDir}/blocks";
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
            url = "${links.prometheus-ingest.url}/api/v1/write";
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
  users.users.tempo = {
    isSystemUser = true;
    group = "tempo";
    home = dataDir;
    createHome = true;
  };

  users.groups.tempo = {};

  systemd.services.tempo = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "tempo";
      Group = "tempo";
      ExecStart = "${pkgs.tempo}/bin/tempo -config.file=${pkgs.writeText "tempo.yaml" (builtins.toJSON tempoConfig)}";
      PrivateTmp = true;
    };
  };
  services.grafana.provision.datasources.settings.datasources = [
    {
      name = "Tempo";
      uid = "P214B5B846CF3925F";
      inherit (links.tempo) url;
      type = "tempo";
      jsonData = {
        serviceMap.datasourceUid = "PBFA97CFB590B2093"; # prometheus
        nodeGraph.enabled = true;
      };
    }
  ];
}
