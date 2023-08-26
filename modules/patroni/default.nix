{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.patroni;
  defaultUser = "patroni";
  defaultGroup = "patroni";
  format = pkgs.formats.yaml { };

  inherit (pkgs) patroni;

  postgresql =
    if cfg.postgresqlExtraPlugins == [ ]
    then cfg.postgresqlPackage
    else cfg.postgresqlPackage.withPackages (_: cfg.postgresqlExtraPlugins);

  configFile = format.generate "patroni.yml" cfg.settings;
in
{
  disabledModules = [
    "services/cluster/patroni/default.nix"
  ];

  options.services.patroni = {

    enable = mkEnableOption "Whether to enable Patroni";

    postgresqlPackage = mkOption {
      type = types.package;
      example = literalExpression "pkgs.postgresql_11";
      description = mdDoc ''
        PostgreSQL package to use.
      '';
    };

    postgresqlExtraPlugins = mkOption {
      type = types.listOf types.path;
      default = [ ];
      example = literalExpression "with pkgs.postgresql_11.pkgs; [ postgis pg_repack ]";
      description = mdDoc ''
        List of PostgreSQL plugins. PostgreSQL version for each plugin should
        match version for `services.postgresql.package` value.
      '';
    };

    postgresqlDataDir = mkOption {
      type = types.path;
      defaultText = literalExpression ''"/var/lib/postgresql/''${config.services.patroni.postgresqlPackage.psqlSchema}"'';
      example = "/var/lib/postgresql/14";
      default = "/var/lib/postgresql/${postgresql.psqlSchema}";
      description = mdDoc ''
        The data directory for PostgreSQL. If left as the default value
        this directory will automatically be created before the PostgreSQL server starts, otherwise
        the sysadmin is responsible for ensuring the directory exists with appropriate ownership
        and permissions.
      '';
    };

    postgresqlPort = mkOption {
      type = types.port;
      default = 5432;
      description = mdDoc ''
        The port on which PostgreSQL listens.
      '';
    };

    user = mkOption {
      type = types.str;
      default = defaultUser;
      example = "postgres";
      description = mdDoc ''
        The user for the service. If left as the default value this user will automatically be created,
        otherwise the sysadmin is responsible for ensuring the user exists.
      '';
    };

    group = mkOption {
      type = types.str;
      default = defaultGroup;
      example = "postgres";
      description = mdDoc ''
        The group for the service. If left as the default value this group will automatically be created,
        otherwise the sysadmin is responsible for ensuring the group exists.
      '';
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/patroni";
      description = mdDoc ''
        Folder where Patroni data will be written, used by Raft as well if enabled.
      '';
    };

    scope = mkOption {
      type = types.str;
      example = "cluster1";
      description = mdDoc ''
        Cluster name.
      '';
    };

    name = mkOption {
      type = types.str;
      example = "node1";
      description = mdDoc ''
        The name of the host. Must be unique for the cluster.
      '';
    };

    namespace = mkOption {
      type = types.str;
      default = "/service";
      description = mdDoc ''
        Path within the configuration store where Patroni will keep information about the cluster.
      '';
    };

    nodeIp = mkOption {
      type = types.str;
      example = "192.168.1.1";
      description = mdDoc ''
        IP address of this node.
      '';
    };

    otherNodesIps = mkOption {
      type = types.listOf types.string;
      example = [ "192.168.1.2" "192.168.1.3" ];
      description = mdDoc ''
        IP addresses of the other nodes.
      '';
    };

    restApiPort = mkOption {
      type = types.port;
      default = 8008;
      description = mdDoc ''
        The port on Patroni's REST api listens.
      '';
    };

    raft = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        This will configure Patroni to use its own RAFT implementation instead of using a dedicated DCS.
      '';
    };

    raftPort = mkOption {
      type = types.port;
      default = 5010;
      description = mdDoc ''
        The port on which RAFT listens.
      '';
    };

    softwareWatchdog = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        This will configure Patroni to use the software watchdog built into the Linux kernel
        as described in the [documentation](https://patroni.readthedocs.io/en/latest/watchdog.html#setting-up-software-watchdog-on-linux).
      '';
    };

    settings = mkOption {
      inherit (format) type;
      default = { };
      description = mdDoc ''
        The primary patroni configuration. See the [documentation](https://patroni.readthedocs.io/en/latest/SETTINGS.html)
        for possible values.
        Secrets should be passed in by using the `environmentFiles` option.
      '';
    };

    environmentFiles = mkOption {
      type = with types; attrsOf (nullOr (oneOf [ str path package ]));
      default = { };
      example = {
        PATRONI_REPLICATION_PASSWORD = "/secret/file";
        PATRONI_SUPERUSER_PASSWORD = "/secret/file";
      };
      description = mdDoc "Environment variables made available to Patroni as files content, useful for providing secrets from files.";
    };

    migrations = {
      enable = mkEnableOption "automatic migrations";

      
      
    };
  };

  config = mkIf cfg.enable {

    services.patroni.settings = {
      inherit (cfg) scope;
      inherit (cfg) name;
      inherit (cfg) namespace;

      bootstrap = mkIf cfg.migrations.enable {
        dcs.postgresql.parameters.wal_level = "logical";
      };

      restapi = {
        listen = "${cfg.nodeIp}:${toString cfg.restApiPort}";
        connect_address = "${cfg.nodeIp}:${toString cfg.restApiPort}";
      };

      raft = mkIf cfg.raft {
        data_dir = "${cfg.dataDir}/raft";
        self_addr = "${cfg.nodeIp}:5010";
        partner_addrs = map (ip: ip + ":5010") cfg.otherNodesIps;
      };

      postgresql = {
        listen = "${cfg.nodeIp}:${toString cfg.postgresqlPort}";
        connect_address = "${cfg.nodeIp}:${toString cfg.postgresqlPort}";
        data_dir = cfg.postgresqlDataDir;
        bin_dir = "${postgresql}/bin";
        pgpass = "${cfg.dataDir}/pgpass";
      };

      watchdog = mkIf cfg.softwareWatchdog {
        mode = "required";
        device = "/dev/watchdog";
        safety_margin = 5;
      };
    };


    users = {
      users = mkIf (cfg.user == defaultUser) {
        patroni = {
          inherit (cfg) group;
          isSystemUser = true;
        };
      };
      groups = mkIf (cfg.group == defaultGroup) {
        patroni = { };
      };
    };

    systemd.services = {
      patroni = {
        description = "Runners to orchestrate a high-availability PostgreSQL";

        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        preStart = let
          upgradeScript = pkgs.writers.writePython3 "patroni-migration-self-upgrade" {
            libraries = [ (pkgs.python3Packages.toPythonModule patroni) ];
            flakeIgnore = [
              "E501"
            ];
          } ''
            import os
            import subprocess
            from datetime import datetime
            from patroni.__main__ import Patroni
            from patroni.config import Config
            from patroni.utils import polling_loop
            
            if __name__ == "__main__":
                print("creating patroni control object")
                ctl = Patroni(Config(os.getenv("PATRONICTL_CONFIG_FILE")))
                pg = ctl.postgresql

                print("running initdb")
                pg.bootstrap._initdb(ctl.config.get("initdb"))

                configuration = pg.config.effective_configuration

                print("configuring postgres")
                pg.config.check_directories()
                pg.config.write_postgresql_conf(configuration)
                pg.config.resolve_connection_addresses()
                pg.config.replace_pg_hba()
                pg.config.replace_pg_ident()

                print("starting postgres")
                pg.start()

                auth = pg.config.get("authentication")
                listen = pg.config.get("listen").split(":")
                leader_host = os.getenv("PATRONIMIGRATOR_LEADER_HOST")
                leader_port = os.getenv("PATRONIMIGRATOR_LEADER_PORT")

                def psql(host=listen[0], port=listen[1], user=auth["superuser"]["username"]):
                    return lambda query: subprocess.run([
                        pg.pgcommand("psql"),
                        "-h", host,
                        "-p", port,
                        "-U", user,
                        "-f", "-"
                    ], input=(query if type(query) is bytes else query.encode("utf8")))

                print("dumping schema")
                args = [
                    pg.pgcommand("pg_dumpall"),
                    "-h", leader_host,
                    "-p", leader_port,
                    "-U", auth["superuser"]["username"],
                    "-s"
                ]
                print("running with args:")
                print(args)
                dump = subprocess.run(args, capture_output=True)
            
                psql_self = psql()
                psql_leader = psql(
                    host=leader_host,
                    port=leader_port
                )
                print("applying schema")
                psql_self(dump.stdout)
                ctime = int((datetime.utcnow() - datetime(1970, 1, 1)).total_seconds())
                pub = f"pub_live_upgrade_{ctime}"
                sub = f"sub_live_upgrade_{ctime}"
                replication_user = auth["superuser"]["username"]
                all_databases = pg.query("SELECT datname FROM pg_database WHERE datistemplate = false;").fetchall()
                for (db,) in all_databases:
                    print(f"creating pub/sub for database {db}")
                    psql_leader(f"""
                    \\connect {db}
                    CREATE PUBLICATION {pub}_{db} FOR ALL TABLES;
                    """)
                    psql_self(f"""
                    \\connect {db}
                    CREATE SUBSCRIPTION {sub}_{db} CONNECTION 'host={leader_host} port={leader_port} dbname={db} user={replication_user}' PUBLICATION {pub}_{db};
                    """)

                # TODO: should probably wait longer
                for _ in polling_loop(300):
                    print("waiting for synchronization to complete")
                    laststate = "?"
                    for (state,) in pg.query("""
                            SELECT srsubstate FROM pg_subscription_rel;
                            """):
                        laststate = state
                        if state != "r":
                            print(f"sync state={state}")
                            break
                    if laststate == "r":
                        break
                print("synchronized!")
                for (db,) in all_databases:
                    print(f"dropping pub/sub for database {db}")
                    psql_self(f"""
                    \\connect {db}
                    DROP SUBSCRIPTION {sub}_{db};
                    """)
                    psql_leader(f"""
                    \\connect {db}
                    DROP PUBLICATION {pub}_{db};
                    """)

                [(sysid,)] = pg.query("SELECT system_identifier FROM pg_control_system();").fetchall()
                print(f"setting system identifier to {sysid}")
                ctl.dcs.initialize(create_new=False, sysid=str(sysid))
                pg.stop()
          '';
          migrationScript = pkgs.writeShellScript "patroni-migration-replicate-or-self-upgrade" ''
            if [[ "$(consul catalog nodes --service='${cfg.scope}' 2>/dev/null | wc -l)" -gt 0 ]]; then
              # check if there's an active leader
              leader="$(patronictl list -f json | jq -r 'map(select(.Role == "Leader" and .State == "running") | .Member) | .[0]')"
              if [[ -n "$leader" ]]; then
                leaderVersion="$(patronictl version '${cfg.scope}' "$leader" | grep -o 'PostgreSQL [0-9]*' | cut -d' ' -f2)"
                if [[ "$leaderVersion" == '${postgresql.psqlSchema}' ]]; then
                  # leader is the same version as our target
                  echo leader is at target version, preparing for reinit
                  # TODO: need to wipe data dir, or will patroni do it for us?
                  rm -rf '${cfg.postgresqlDataDir}'
                  exit 0
                else
                  echo leader version $leaderVersion differs from target version ${postgresql.psqlSchema}, trying to find an upgraded replica
                  for replica in $(patronictl list -f json | jq -r 'map(select(.Role == "Replica" and .State == "running") | .Member) | .[]'); do
                    replicaVersion="$(patronictl version '${cfg.scope}' "$replica" | grep -o 'PostgreSQL [0-9]*' | cut -d' ' -f2)"
                    if [[ "$replicaVersion" == '${postgresql.psqlSchema}' ]]; then
                      # another replica is the same version as us, make leader
                      echo found a replica with the same target version, attempting to promote it to leader
                      # TODO: do we need to force it to become the leader or is there another way?
                      if ! patronictl switchover '${cfg.scope}' --master "$leader" --candidate "$replica" --force --scheduled now; then
                        echo switchover failed! attempting failover
                        patronictl failover '${cfg.scope}' --candidate "$replica" --force
                      fi
                      while [[ "$(patronictl list -f json | jq -r 'map(select(.Role == "Leader" and .State == "running") | .Member) | .[0]')" != "$replica" ]]; do
                        echo waiting for "$replica" to become the leader
                        patronictl list
                        sleep 1
                      done
                      echo preparing for reinit after leader promotion
                      # TODO: need to wipe data dir, or will patroni do it for us?
                      rm -rf '${cfg.postgresqlDataDir}'
                      exit 0
                    fi
                  done
                  echo no other nodes are at the target version, performing self-upgrade
                  leaderHost="$(patronictl list -f json | jq -r 'map(select(.Role == "Leader" and .State == "running") | .Host) | .[0]')"
                  # this is where it gets spicy
                  rm -rf '${cfg.postgresqlDataDir}'
                  install -dm700 '${cfg.postgresqlDataDir}'
                  # give the migration script 1800 seconds
                  systemd-notify EXTEND_TIMEOUT_USEC=1800000000
                  export PATRONIMIGRATOR_LEADER_HOST="$leaderHost"
                  # HACK: find a way to get the port
                  export PATRONIMIGRATOR_LEADER_PORT="5432"
                  exec ${upgradeScript}
                fi
              fi
            fi
            echo consul returned no nodes, proceeding with cluster bootstrap
            # no other nodes around, nothing we can do
          '';
        in mkIf cfg.migrations.enable /*bash*/ ''
          export PATH=${makeBinPath [ pkgs.jq pkgs.gnugrep config.services.consul.package patroni ]}:$PATH
          export PATRONICTL_CONFIG_FILE=${configFile}
          set -e
          pgVersion='${cfg.postgresqlDataDir}/PG_VERSION'
          # don't do anything if already at the target version
          if [[ -e "$pgVersion" && "$(<"$pgVersion")" == '${postgresql.psqlSchema}' ]]; then
            echo data directory version is target, no migrations to run
            exit 0
          fi
          # HACK:
          export CONSUL_HTTP_ADDR=192.168.1.4:8500
          # ask consul if there are any other nodes around
          exec consul lock --verbose --child-exit-code --shell=false '/patroni-migrator-upgrade/${cfg.scope}' ${migrationScript}
        '';

        script = ''
          ${concatStringsSep "\n" (attrValues (mapAttrs (name: path: "export ${name}=\"$(<'${path}')\"") cfg.environmentFiles))}
          exec ${patroni}/bin/patroni ${configFile}
        '';

        preStop = ''
          export PATH=${makeBinPath [ pkgs.jq patroni ]}:$PATH
          export PATRONICTL_CONFIG_FILE=${configFile}
          if [[ "$(patronictl list -f json | jq -r '.[] | select(.Member == "${cfg.name}") | .Role')" != "Leader" ]]; then
            # not leader, exit right away
            kill -SIGTERM $MAINPID
            exit 0
          fi
          echo "I am the leader. Waiting 10 seconds before beginning shutdown procedure."
          sleep 10
          count=0
          maxCount=60
          while [[ "$(patronictl list -f json | jq 'map(select(.State == "running")) | length')" -lt 2 ]]; do
            if [[ $count -ge $maxCount ]]; then
              echo "Timeout: No replica to hand off to."
              exit 1
            fi
            count=$((count + 1))
            echo "Waiting for a member to hand off to before shutting down... [$count/$maxCount]"
            # extend timeout by 30 seconds if required
            systemd-notify EXTEND_TIMEOUT_USEC=30000000
            sleep 10
          done
          echo "Found active replica for hand-off, shutting down now."
          # give Patroni 300 seconds to shut down afterwards
          systemd-notify EXTEND_TIMEOUT_USEC=300000000
        '';

        strictMounts = [ cfg.dataDir cfg.postgresqlDataDir ];

        serviceConfig = mkMerge [{
          User = cfg.user;
          Group = cfg.group;
          Type = "simple";
          Restart = "on-failure";
          TimeoutSec = 30;
          ExecReload = "${pkgs.coreutils}/bin/kill -s HUP $MAINPID";
          NotifyAccess = "all";
          KillMode = "process";
        }
          (mkIf (cfg.postgresqlDataDir == "/var/lib/postgresql/${postgresql.psqlSchema}" && cfg.dataDir == "/var/lib/patroni") {
            StateDirectory = "patroni patroni/raft postgresql postgresql/${postgresql.psqlSchema}";
            StateDirectoryMode = "0750";
          })
          (mkIf cfg.softwareWatchdog {
            ExecStartPre = [("+" + pkgs.writeShellScript "configure-software-watchdog.sh" ''
              ${pkgs.kmod}/bin/modprobe softdog
              ${pkgs.coreutils}/bin/chown ${cfg.user} /dev/watchdog
            '')];
          })];
      };
    };

    environment.systemPackages = [
      patroni
      postgresql
      (mkIf cfg.raft pkgs.python310Packages.pysyncobj)
      (pkgs.python3.withPackages (_: [ (pkgs.python3Packages.toPythonModule patroni) ]))
    ];

    environment.sessionVariables = {
      PATRONICTL_CONFIG_FILE = "${configFile}";
    };

    systemd.tmpfiles.rules = mkIf (cfg.postgresqlDataDir != "/var/lib/postgresql/${postgresql.psqlSchema}" || cfg.dataDir != "/var/lib/patroni") [
      "d '${cfg.dataDir}' 0700 ${cfg.user} ${cfg.group} - -"
    ];
  };
}
