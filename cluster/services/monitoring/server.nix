{ cluster, config, depot, lib, tools, ... }:
let
  inherit (tools.meta) domain;

  inherit (config) links;

  inherit (cluster.config.links) loki-ingest prometheus-ingest;

  iniList = lib.concatStringsSep " ";

  login = x: "https://login.${domain}/auth/realms/master/protocol/openid-connect/${x}";
in
{
  age.secrets = {
    grafana-db-credentials = {
      file = ./secrets/grafana-db-credentials.age;
      owner = "grafana";
    };
    grafana-secrets.file = ./secrets/grafana-secrets.age;
  };

  links = {
    grafana.protocol = "http";
  };
  services.grafana = {
    enable = true;
    package = depot.packages.grafana;
    dataDir = "/srv/storage/private/grafana";
    settings = {
      server = {
        root_url = "https://monitoring.${domain}/";
        http_port = links.grafana.port;
      };
      database = {
        type = "postgres";
        host = cluster.config.links.patroni-pg-access.tuple;
        user = "grafana";
        password = "$__file{${config.age.secrets.grafana-db-credentials.path}}";
      };
      analytics.reporting_enabled = false;
      "auth.generic_oauth" = {
        enabled = true;
        allow_sign_up = true;
        client_id = "net.privatevoid.monitoring1";
        auth_url = login "auth";
        token_url = login "token";
        api_url = login "userinfo";
        scopes = iniList [ "openid" "profile" "email" "roles" ];
        role_attribute_strict = true;
        role_attribute_path = "resource_access.monitoring.roles[0]";
      };
      security = {
        cookie_secure = true;
        disable_gravatar = true;
      };
      feature_toggles.enable = iniList [
        "tempoSearch"
        "tempoBackendSearch"
        "tempoServiceGraph"
      ];
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          uid = "PBFA97CFB590B2093";
          inherit (prometheus-ingest) url;
          type = "prometheus";
          isDefault = true;
        }
        {
          name = "Loki";
          uid = "P8E80F9AEF21F6940";
          inherit (loki-ingest) url;
          type = "loki";
        }
      ];
    };
  };

  systemd.services.grafana.serviceConfig = {
    EnvironmentFile = config.age.secrets.grafana-secrets.path;
  };

  services.nginx.virtualHosts."monitoring.${domain}" = lib.recursiveUpdate (tools.nginx.vhosts.proxy links.grafana.url) {
    locations."/".proxyWebsockets = true;
  };

  services.prometheus = {
    enable = true;
    listenAddress = prometheus-ingest.ipv4;
    inherit (prometheus-ingest) port;
    extraFlags = [ "--enable-feature=remote-write-receiver" ];
    globalConfig = {
      scrape_interval = "60s";
    };
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = lib.flip lib.mapAttrsToList cluster.config.vars.mesh (name: host: {
          targets = [ "${host.meshIp}:9100" ];
          labels.instance = name;
        });
      }
        {
          job_name = "ipfs";
          scheme = "https";
          metrics_path = "/debug/metrics/prometheus";
          static_configs = [
            {
              targets = [ "ipfs.admin.${domain}" ];
              labels.instance = "VEGAS";
            }
          ];
        }
    ];
  };

}
