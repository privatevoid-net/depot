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
  };

  config = mkIf cfg.enable {

    services.patroni.settings = {
      inherit (cfg) scope;
      inherit (cfg) name;
      inherit (cfg) namespace;

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

        unitConfig.RequiresMountsFor = [ cfg.dataDir cfg.postgresqlDataDir ];

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
            ExecStartPre = "+" + pkgs.writeShellScript "configure-software-watchdog.sh" ''
              ${pkgs.kmod}/bin/modprobe softdog
              ${pkgs.coreutils}/bin/chown ${cfg.user} /dev/watchdog
            '';
          })];
      };
    };

    environment.systemPackages = [
      patroni
      postgresql
      (mkIf cfg.raft pkgs.python310Packages.pysyncobj)
    ];

    environment.sessionVariables = {
      PATRONICTL_CONFIG_FILE = "${configFile}";
    };

    systemd.tmpfiles.rules = mkIf (cfg.postgresqlDataDir != "/var/lib/postgresql/${postgresql.psqlSchema}" || cfg.dataDir != "/var/lib/patroni") [
      "d '${cfg.dataDir}' 0700 ${cfg.user} ${cfg.group} - -"
    ];
  };
}
