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
  s3Config = {
    module = "s3_storage_provider.S3StorageProviderBackend";
    store_local = true;
    store_remote = true;
    store_synchronous = true;
    config = {
      bucket = "matrix-media";
      region_name = "us-east-1";
      endpoint_url = cluster.config.links.garageS3.url;
    };
  };

  clientConfigJSON = pkgs.writeText "matrix-client-config.json" (builtins.toJSON clientConfig);
  logConfigJSON = pkgs.writeText "matrix-log-config.json" (builtins.toJSON logConfig);
  dbConfigJSON = pkgs.writeText "matrix-db-config.json" (builtins.toJSON dbConfig);
  dbPasswordFile = secrets.dbConfig.path;
  dbConfigOut = "${cfg.dataDir}/synapse-db-config-generated.json";

  s3ConfigJSON = pkgs.writeText "matrix-s3-config.json" (builtins.toJSON s3Config);
  s3ConfigOut = "${cfg.dataDir}/synapse-s3-config-generated.json";

  cfg = config.services.matrix-synapse;
  serviceCfg = config.systemd.services.matrix-synapse.serviceConfig;
in {
  services.matrix-synapse = {
    enable = true;
    plugins = with config.services.matrix-synapse.package.plugins; [
      matrix-synapse-ldap3
      matrix-synapse-s3-storage-provider
    ];
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
    ]) ++ [ dbConfigOut s3ConfigOut ];
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
        ${pkgs.jq}/bin/jq -c < ${s3ConfigJSON} \
          --rawfile accessKey /run/locksmith/garage-synapse-id \
          --rawfile secretKey /run/locksmith/garage-synapse-secret '{
          media_storage_providers: [
            (. * {
              config: {
                access_key_id: $accessKey | gsub("\\n"; ""),
                secret_access_key: $secretKey | gsub("\\n"; "")
              }
            })
          ]
        }' | install -Dm400 /dev/stdin '${s3ConfigOut}'
      '';
    }
    {
      matrix-synapse.serviceConfig.TimeoutStartSec = 600;
    }
    {
      matrix-media-upload = {
        after = [ cfg.serviceUnit ];
        requires = [ cfg.serviceUnit ];
        serviceConfig = {
          Type = "oneshot";
          inherit (serviceCfg) User Group WorkingDirectory;
          PrivateTmp = true;
        };
        path = [
          pkgs.jq
          cfg.package.plugins.matrix-synapse-s3-storage-provider
        ];
        script = ''
          jq < '${dbConfigOut}' '{
            database: .database.args.database,
            host: .database.args.host,
            port: .database.args.port,
            user: .database.args.user,
            password: .database.args.password
          }' | install -Dm400 /dev/stdin database.yaml
          export AWS_ACCESS_KEY_ID="$(cat /run/locksmith/garage-synapse-id)"
          export AWS_SECRET_ACCESS_KEY="$(cat /run/locksmith/garage-synapse-secret)"
          s3_media_upload --no-progress update-db 1d --homeserver-config-path '${dbConfigOut}'
          s3_media_upload --no-progress check-deleted media
          s3_media_upload --no-progress upload --delete media matrix-media --endpoint-url '${cluster.config.links.garageS3.url}'
        '';
      };
    }
  ];

  systemd.timers.matrix-media-upload = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "24h";
      OnUnitActiveSec = "24h";
      RandomizedDelaySec = "6h";
    };
  };
}
