{ cluster, config, depot, lib, ... }:

let
  inherit (cluster.config) vars;
  inherit (cluster.config.services.patroni) secrets;
  inherit (config.networking) hostName;

  getMeshIp = name: vars.mesh.${name}.meshIp;

  net = vars.meshNet.cidr;

  pg = depot.packages.postgresql;

  baseDir = "/srv/storage/database/postgres-ha";

  walDir = "/var/lib/postgres-ha/${pg.psqlSchema}/wal";
in

{
  imports = [
    depot.nixosModules.patroni
  ];

  systemd.tmpfiles.rules = [
    "d '${baseDir}' 0700 patroni patroni - -"
    "d '${walDir}' 0700 patroni patroni - -"
  ];
  services.patroni = {
    enable = true;
    name = hostName;
    postgresqlPackage = pg;
    postgresqlDataDir ="${baseDir}/${pg.psqlSchema}";
    postgresqlPort = cluster.config.links.patroni-pg-internal.port;
    restApiPort = cluster.config.links.patroni-api.port;
    scope = "poseidon";
    namespace = "/patroni";

    nodeIp = getMeshIp hostName;
    otherNodesIps = map getMeshIp (cluster.config.services.patroni.otherNodes.worker hostName);
    raft = false;
    softwareWatchdog = true;
    settings = {
      consul = {
        host = "127.0.0.1:8500";
        register_service = true;
      };
      bootstrap.dcs = {
        ttl = 30;
        loop_wait = 10;
        retry_timeout = 10;
        maximum_lag_on_failover = 1024 * 1024;
      };
      failsafe_mode = true;
      postgresql = {
        basebackup = {
          waldir = walDir;
        };
        use_pg_rewind = true;
        use_slots = true;
        authentication = {
          replication.username = "patronirep";
          rewind.username = "patronirew";
          superuser.username = "postgres";
        };
        parameters = {
          listen_addresses = getMeshIp hostName;
          wal_level = "replica";
          hot_standby_feedback = "on";
          unix_socket_directories = "/tmp";
        };
        pg_hba = [
          "host replication patronirep ${net} scram-sha-256"
          "host all patronirew ${net} scram-sha-256"
          "host all postgres ${net} scram-sha-256"
          "host all all ${net} scram-sha-256"
          "host all all 127.0.0.1/32 scram-sha-256"
        ];
      };
    };
    environmentFiles = lib.mapAttrs (_: secret: secret.path) (lib.filterAttrs (name: _: lib.hasPrefix "PATRONI_" name) secrets);
  };
}
