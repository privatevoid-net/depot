{ aspect, cluster, config, lib, pkgs, ... }:

let
  inherit (cluster.config) vars;

  getMeshIp = name: vars.mesh.${name}.meshIp;

  net = vars.meshNet.cidr;

  pg = pkgs.postgresql_14;

  baseDir = "/srv/storage/database/postgres-ha";
in

{
  imports = [
    aspect.modules.patroni
  ];

  age.secrets = lib.mapAttrs (_: file: {
    inherit file;
    mode = "0400";
    owner = "patroni";
    group = "patroni";
  }) vars.patroni.passwords;

  systemd.tmpfiles.rules = [ "d '${baseDir}' 0700 patroni patroni - -" ];
  services.patroni = {
    enable = true;
    name = vars.hostName;
    postgresqlPackage = pg;
    postgresqlDataDir ="${baseDir}/${pg.psqlSchema}";
    postgresqlPort = cluster.config.links.patroni-pg-internal.port;
    restApiPort = cluster.config.links.patroni-api.port;
    scope = "poseidon";
    namespace = "/patroni";

    nodeIp = getMeshIp vars.hostName;
    otherNodesIps = map getMeshIp cluster.config.services.patroni.otherNodes.worker;
    raft = false;
    softwareWatchdog = true;
    settings = {
      consul.host = "127.0.0.1:8500";
      bootstrap.dcs = {
        ttl = 30;
        loop_wait = 10;
        retry_timeout = 10;
        maximum_lag_on_failover = 1024 * 1024;
      };
      postgresql = {
        use_pg_rewind = true;
        use_slots = true;
        authentication = {
          replication.username = "patronirep";
          rewind.username = "patronirew";
          superuser.username = "postgres";
        };
        parameters = {
          listen_addresses = getMeshIp vars.hostName;
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
    environmentFiles = lib.mapAttrs (n: _: config.age.secrets.${n}.path) vars.patroni.passwords;
  };

  consul.services.patroni = {
    mode = "external";
    definition = rec {
      name = "patroni";
      address = getMeshIp vars.hostName;
      port = cluster.config.links.patroni-pg-internal.port;
      checks = lib.singleton {
        interval = "5s";
        http = "http://${address}:${cluster.config.links.patroni-api.portStr}";
      };
    };
  };
}
