{ config, lib, pkgs, options, ... }:
with lib;
let
  cfg = config.services.ipfs-cluster;
  opt = options.services.ipfs-cluster;

  # secret is by envvar, not flag
  initFlags = toString [
    (optionalString (cfg.initPeers != [ ]) "--peers")
    (lib.strings.concatStringsSep "," cfg.initPeers)
  ];
in {

  ###### interface

  options = {

    services.ipfs-cluster = {

      enable = mkEnableOption
        "Pinset orchestration for IPFS - requires ipfs daemon to be useful";

      package = mkOption {
        type = types.package;
        default = pkgs.ipfs-cluster;
        description = "ipfs-cluster package";
      };

      user = mkOption {
        type = types.str;
        default = "ipfs";
        description = "User under which the ipfs-cluster daemon runs.";
      };

      group = mkOption {
        type = types.str;
        default = "ipfs";
        description = "Group under which the ipfs-cluster daemon runs.";
      };

      consensus = mkOption {
        type = types.enum [ "raft" "crdt" ];
        description = "Consensus protocol - 'raft' or 'crdt'. https://cluster.ipfs.io/documentation/guides/consensus/";
      };

      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/ipfs-cluster";
        description = "The data dir for ipfs-cluster.";
      };

      initPeers = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Peer addresses to initialize with on first run.";
      };

      openSwarmPort = mkOption {
        type = types.bool;
        description = "Open swarm port, secured by the cluster secret. This does not expose the API or proxy. https://cluster.ipfs.io/documentation/guides/security/";
      };

      secretFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          File containing the cluster secret in the format of EnvironmentFile as described by
          <citerefentry><refentrytitle>systemd.exec</refentrytitle>
          <manvolnum>5</manvolnum></citerefentry>. For example:
          <programlisting>
          CLUSTER_SECRET=<replaceable>...</replaceable>
          </programlisting>

          if null, a new secret will be generated on first run.
          A secret in the correct format can also be generated by: openssl rand -hex 32
        '';
      };
    };
  };

  ###### implementation

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];


    systemd.tmpfiles.rules =
      [ "d '${cfg.dataDir}' - ${cfg.user} ${cfg.group} - -" ];

    systemd.services.ipfs-cluster-init = {
      path = [ "/run/wrappers" cfg.package ];
      environment.IPFS_CLUSTER_PATH = cfg.dataDir;
      wantedBy = [ "default.target" ];

      serviceConfig = {
        # "" clears exec list (man systemd.service -> execStart)
        ExecStart = [
          ""
          "${cfg.package}/bin/ipfs-cluster-service init --consensus ${cfg.consensus} ${initFlags}"
        ];
        Type = "oneshot";
        RemainAfterExit = true;
        User = cfg.user;
        Group = cfg.group;
        } // optionalAttrs (cfg.secretFile != null) {
          EnvironmentFile = cfg.secretFile;
        };
      unitConfig.ConditionDirectoryNotEmpty = "!${cfg.dataDir}";
    };

    systemd.services.ipfs-cluster = {
      environment.IPFS_CLUSTER_PATH = cfg.dataDir;
      wantedBy = [ "multi-user.target" ];

      wants = [ "ipfs-cluster-init.service" ];
      after = [ "ipfs-cluster-init.service" ];

      serviceConfig = {
        ExecStart =
          [ "" "${cfg.package}/bin/ipfs-cluster-service daemon" ];
        User = cfg.user;
        Group = cfg.group;
      };
    };
    networking.firewall.allowedTCPPorts = mkIf cfg.openSwarmPort [ 9096 ];
  };
}