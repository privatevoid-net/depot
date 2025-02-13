{ cluster, config, lib, pkgs, depot, ... }:
let
  inherit (depot.lib.meta) domain;
  inherit (cluster.config.services.matrix) secrets;

  patroni = cluster.config.links.patroni-pg-access;

  listener = {
    port = 8008;
    bind_addresses = lib.singleton "127.0.0.1";
    type = "http";
    tls = false;
    x_forwarded = true;
    resources = lib.singleton {
      names = [ "client" "federation" ];
      compress = false;
    };
  };
  clientConfig = {
    "m.homeserver".base_url = "https://matrix.${domain}:443";
    "m.integrations".managers = [{
      api_url = "https://dimension.t2bot.io/api/v1/scalar";
      ui_url = "https://dimension.t2bot.io/riot";
    }];
  } // lib.optionalAttrs config.services.jitsi-meet.enable {
    "im.vector.riot.jitsi".preferredDomain = config.services.jitsi-meet.hostName;
  };
  logConfig = {
    version = 1;
    formatters.structured.class = "synapse.logging.TerseJsonFormatter";
    handlers.journal = {
      class = "systemd.journal.JournalHandler";
      formatter = "structured";
      SYSLOG_IDENTIFIER = "synapse";
    };
    loggers.synapse = {
      level = "WARNING";
      handlers = [ "journal" ];
    };
  };
  dbConfig.database = {
    name = "psycopg2";
    args = {
      user = "matrix";
      database = "matrix";
      host = patroni.ipv4;
      inherit (patroni) port;
      cp_min = 1;
      cp_max = 10;
    };
  };
  clientConfigJSON = pkgs.writeText "matrix-client-config.json" (builtins.toJSON clientConfig);
  logConfigJSON = pkgs.writeText "matrix-log-config.json" (builtins.toJSON logConfig);
  dbConfigJSON = pkgs.writeText "matrix-log-config.json" (builtins.toJSON dbConfig);
  dbPasswordFile = secrets.dbConfig.path;
  dbConfigOut = "${cfg.dataDir}/synapse-db-config-generated.yml";
  cfg = config.services.matrix-synapse;
in {
  services.matrix-synapse = {
    enable = true;
    plugins = [ pkgs.matrix-synapse-plugins.matrix-synapse-ldap3 ];
    dataDir = "/srv/storage/private/matrix";

    settings = {
      server_name = domain;
      listeners = lib.singleton listener;
      url_preview_enabled = true;
      experimental_features.spaces_enabled = true;
      admin_contact = "mailto:admins@${domain}";
      max_upload_size = "32M";
      max_spider_size = "10M";
      emable_registration = true;
      allow_guest_access = true;
      push.include_content = true;
      group_creation_prefix = "unofficial/";
      log_config = logConfigJSON;
      # HACK: upstream has a weird assertion that doesn't work with our HAProxy setup
      # this host gets overridden by dbConfigOut
      database = lib.recursiveUpdate dbConfig.database { args.host = "_patroni.local"; };
      turn_uris = let
        combinations = lib.cartesianProduct {
          proto = [ "udp" "tcp" ];
          scheme = [ "turns" "turn" ];
        };
        makeTurnServer = x: "${x.scheme}:turn.${domain}?transport=${x.proto}";
      in map makeTurnServer combinations;
    };

    extraConfigFiles = (map (x: secrets."${x}Config".path) [
      "ldap"
      "turn"
      "keys"
    ]) ++ [ dbConfigOut ];
  };

  services.nginx.virtualHosts = depot.lib.nginx.mappers.mapSubdomains {
    matrix = depot.lib.nginx.vhosts.basic // {
      locations."/".return = "204";
      locations."/_matrix" = {
        proxyPass = "http://127.0.0.1:8008";
        extraConfig = ''
          client_max_body_size ${cfg.settings.max_upload_size};
          access_log off;
        '';
      };
      locations."= /.well-known/matrix/client" = {
        alias = clientConfigJSON;
        extraConfig = ''
          add_header Access-Control-Allow-Origin "*";
        '';
      };
    };
  };
  systemd.services = lib.mkMerge [
    (lib.genAttrs [ "coturn" "matrix-synapse" ] (_: {
      serviceConfig = {
        Slice = "communications.slice";
      };
    }))
    {
      matrix-synapse.preStart = ''
        ${pkgs.jq}/bin/jq -c --slurp '.[0] * .[1]' ${dbConfigJSON} '${dbPasswordFile}' | install -Dm400 /dev/stdin '${dbConfigOut}'
      '';
    }
  ];
}
