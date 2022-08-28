{ nixosTest, tempo, writeText }:

nixosTest {
  name = "tempo";
  nodes.machine = let
    dataDir = "/var/lib/tempo";
    tempoConfig = {
      search_enabled = true;
      metrics_generator_enabled = true;
      server = {
        http_listen_address = "127.0.0.1";
        http_listen_port = 8888;
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
      metrics_generator = {
        registry.external_labels = {
          source = "tempo";
        };
        storage = {
          path = "${dataDir}/generator/wal";
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
        ExecStart = "${tempo}/bin/tempo -config.file=${writeText "tempo.yaml" (builtins.toJSON tempoConfig)}";
        PrivateTmp = true;
      };
    };
  };
  testScript = ''
    machine.wait_for_unit("tempo.service")
    machine.wait_for_open_port("8888")
    machine.succeed("curl --fail http://127.0.0.1:8888/status/version")
  '';
}
