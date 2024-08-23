{ cluster, config, depot, lib, ... }:
let
  inherit (depot.lib.meta) domain;

  inherit (cluster.config.links) prometheus-ingest;

  inherit (cluster.config) hostLinks;

  inherit (config.networking) hostName;

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

  services.grafana = {
    enable = true;
    settings = {
      server = {
        root_url = "https://monitoring.${domain}/";
        http_addr = hostLinks.${hostName}.grafana.ipv4;
        http_port = hostLinks.${hostName}.grafana.port;
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
          inherit (cluster.config.ways.monitoring-logs) url;
          type = "loki";
        }
        {
          name = "Tempo";
          uid = "P214B5B846CF3925F";
          inherit (cluster.config.ways.monitoring-traces) url;
          type = "tempo";
          jsonData = {
            serviceMap.datasourceUid = "PBFA97CFB590B2093";
            nodeGraph.enabled = true;
          };
        }
      ];
    };
  };

  systemd.services = {
    grafana = {
      distributed = {
        enable = true;
        registerService = "grafana";
      };
      serviceConfig = {
        EnvironmentFile = config.age.secrets.grafana-secrets.path;
        Restart = lib.mkForce "always";
        RestartSec = "10s";
      };
    };
  };

  consul.services.grafana = {
    mode = "manual";
    definition = {
      name = "grafana";
      address = hostLinks.${hostName}.grafana.ipv4;
      port = hostLinks.${hostName}.grafana.port;
      checks = [
        {
          name = "Grafana";
          id = "service:grafana:backend";
          interval = "5s";
          http = "${hostLinks.${hostName}.grafana.url}/healthz";
        }
      ];
    };
  };
}
