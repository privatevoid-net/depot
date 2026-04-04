{ cluster, config, lib, pkgs, depot, ... }:
let
  inherit (depot.lib.meta) domain;
  inherit (cluster.config.services.matrix) secrets;

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
  s3Config = {
    module = "s3_storage_provider.S3StorageProviderBackend";
    store_local = true;
    store_remote = false;
    store_synchronous = false;
    config = {
      bucket = "matrix-media";
      region_name = "us-east-1";
      endpoint_url = cluster.config.links.garageS3.url;
    };
  };

  clientConfigJSON = pkgs.writeText "matrix-client-config.json" (builtins.toJSON clientConfig);
  logConfigJSON = pkgs.writeText "matrix-log-config.json" (builtins.toJSON logConfig);

  s3ConfigJSON = pkgs.writeText "matrix-s3-config.json" (builtins.toJSON s3Config);
  s3ConfigOut = "${cfg.dataDir}/synapse-s3-config-generated.json";

  cfg = config.services.matrix-synapse;
in {
  services.postgresql = {
    enable = true;
    identMap = "matrix matrix-synapse matrix";
    authentication = "local matrix matrix peer map=matrix";
    ensureDatabases = [ "matrix" ];
    ensureUsers = [
      {
        name = "matrix";
        ensureDBOwnership = true;
      }
    ];
  };

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
      database = {
        name = "psycopg2";
        args = {
          user = "matrix";
          database = "matrix";
          cp_min = 1;
          cp_max = 10;
        };
      };
    };

    extraConfigFiles = (map (x: secrets."${x}Config".path) [
      "ldap"
      "keys"
    ]) ++ [ s3ConfigOut ];
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
    {
      matrix-synapse.preStart = ''
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
  ];
}
