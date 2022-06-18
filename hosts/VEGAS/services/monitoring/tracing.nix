{ config, pkgs, ... }:

let
  inherit (config) links;
  dataDir = "/srv/storage/private/tempo";
  tempoConfig = {
    search_enabled = true;
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
      block = {
        bloom_filter_false_positive = 0.05;
        index_downsample_bytes = 1000;
        encoding = "zstd";
      };
      wal.path = "${dataDir}/wal";
      wal.encoding = "snappy";
      local.path = "${dataDir}/blocks";
      pool = {
        max_workers = 16;
        queue_depth = 1000;
      };
    };
  };
in {
  links = {
    tempo.protocol = "http";
    tempo-grpc.protocol = "http";
    tempo-otlp-http.protocol = "http";
    tempo-otlp-grpc.protocol = "http";
  };

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
  services.grafana.provision.datasources = [
    {
      name = "Tempo";
      inherit (links.tempo) url;
      type = "tempo";
    }
  ];
}
