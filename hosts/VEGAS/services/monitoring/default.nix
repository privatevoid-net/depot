{ config, hosts, lib, tools, ... }:
let
  inherit (tools.meta) domain;

  inherit (config) ports portsStr;

  cfg = { inherit (config.services) loki; };

  toString' = v:
    if v == true then "true" else
    if v == false then "false" else
    toString v;

  mapPaths = lib.mapAttrsRecursive (
    path: value: lib.nameValuePair
      (lib.toUpper (lib.concatStringsSep "_" path))
      (toString' value)
  );

  translateConfig = config: lib.listToAttrs (
    lib.collect
      (x: x ? name && x ? value)
      (mapPaths config)
  );

  login = x: "https://login.${domain}/auth/realms/master/protocol/openid-connect/${x}";

  filteredHosts = lib.filterAttrs (_: host: host ? hypr && host ? nixos) hosts;

  myNode = hosts.${config.networking.hostName};
in
{
  age.secrets.grafana-secrets = {
    file = ../../../../secrets/grafana-secrets.age;
  };

  reservePortsFor = [ "grafana" "prometheus" "loki" "loki-grpc" ];
  services.grafana = {
    enable = true;
    port = ports.grafana;
    rootUrl = "https://monitoring.${domain}/";
    dataDir = "/srv/storage/private/grafana";
    analytics.reporting.enable = false;
    extraOptions = translateConfig {
      auth.generic_oauth = {
        enabled = true;
        allow_sign_up = true;
        client_id = "net.privatevoid.monitoring1";
        auth_url = login "auth";
        token_url = login "token";
        api_url = login "userinfo";
        scopes = [ "openid" "profile" "email" "roles" ];
        role_attribute_strict = true;
        role_attribute_path = "resource_access.monitoring.roles[0]";
      };
      security = {
        cookie_secure = true;
        disable_gravatar = true;
      };
    };
    provision = {
      enable = true;
      datasources = [
        {
          name = "Prometheus";
          url = "http://127.0.0.1:${portsStr.prometheus}";
          type = "prometheus";
          isDefault = true;
        }
        {
          name = "Loki";
          url = "http://${myNode.hypr.addr}:${portsStr.loki}";
          type = "loki";
        }
      ];
    };
  };

  systemd.services.grafana.serviceConfig = {
    EnvironmentFile = config.age.secrets.grafana-secrets.path;
  };

  services.nginx.virtualHosts."monitoring.${domain}" = tools.nginx.vhosts.proxy "http://127.0.0.1:${portsStr.grafana}";

  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = ports.prometheus;
    globalConfig = {
      scrape_interval = "60s";
    };
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = lib.flip lib.mapAttrsToList filteredHosts (name: host: {
          targets = [ "${host.hypr.addr}:9100" ];
          labels.instance = name;
        });
      }
      {
        job_name = "jitsi";
        static_configs = [
          {
            targets = [ "${hosts.prophet.hypr.addr}:9700" ];
            labels.instance = "meet.${domain}";
          }
        ];
      }
    ];
  };

  services.loki = {
    enable = true;
    dataDir = "/srv/storage/private/loki";
    configuration = {
      auth_enabled = false;
      server = {
        http_listen_address = myNode.hypr.addr;
        http_listen_port = ports.loki;
        grpc_listen_address = "127.0.0.1";
        grpc_listen_port = ports.loki-grpc;
      };
      ingester = {
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore.store = "inmemory";
            replication_factor = 1;
          };
          final_sleep = "0s";
        };
        chunk_idle_period = "5m";
        chunk_retain_period = "30s";
      };
      schema_config.configs = [
        {
          from = "2022-05-14";
          store = "boltdb";
          object_store = "filesystem";
          schema = "v11";
          index = {
            prefix = "index_";
            period = "168h";
          };
        }
      ];
      storage_config = {
        boltdb.directory = "${cfg.loki.dataDir}/boltdb-index";
        filesystem.directory = "${cfg.loki.dataDir}/storage-chunks";
      };
      limits_config = {
        enforce_metric_name = false;
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
      };
    };
  };
}
