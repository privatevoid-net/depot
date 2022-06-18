{ config, pkgs, ... }:

let
  dataDir = "/srv/storage/private/tempo";
  tempoConfig = {
    server = {
      http_listen_address = "127.0.0.1";
      http_listen_port = config.ports.tempo;
      grpc_listen_address = "127.0.0.1";
      grpc_listen_port = config.ports.tempo-grpc;
    };
    distributor.receivers.otlp = {
      protocols = {
        http.endpoint = "127.0.0.1:${config.portsStr.tempo-otlp-http}";
        grpc.endpoint = "127.0.0.1:${config.portsStr.tempo-otlp-grpc}";
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
  reservePortsFor = [ "tempo" "tempo-grpc" "tempo-otlp-http" "tempo-otlp-grpc" ];

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
      ExecStart = "${pkgs.tempo}/bin/tempo -config.file=${pkgs.writeText "tempo.yaml" (builtins.toJSON tempoConfig)}";
      PrivateTmp = true;
    };
  };
  services.grafana.provision.datasources = [
    {
      name = "Tempo";
      url = "http://127.0.0.1:${config.portsStr.tempo}";
      type = "tempo";
    }
  ];
}
