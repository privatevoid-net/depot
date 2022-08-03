{ cluster, config, hosts, inputs, lib, pkgs, tools, ... }:
let
  inherit (tools.meta) domain;

  inherit (config) links;

  inherit (cluster.config.links) loki-ingest;

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
  imports = [
    ./tracing.nix
  ];
  age.secrets.grafana-secrets = {
    file = ../../../../secrets/grafana-secrets.age;
  };

  links = {
    grafana.protocol = "http";
    prometheus.protocol = "http";
    loki-grpc = {
      protocol = "grpc";
    };
  };
  services.grafana = {
    enable = true;
    package = inputs.self.packages.${pkgs.system}.grafana;
    inherit (links.grafana) port;
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
      feature_toggles.enable = [
        "tempoSearch"
        "tempoBackendSearch"
        "tempoServiceGraph"
      ];
    };
    provision = {
      enable = true;
      datasources = [
        {
          name = "Prometheus";
          # wait for https://github.com/NixOS/nixpkgs/pull/175330
          # uid = "PBFA97CFB590B2093";
          inherit (links.prometheus) url;
          type = "prometheus";
          isDefault = true;
        }
        {
          name = "Loki";
          # uid = "P8E80F9AEF21F6940";
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
    listenAddress = links.prometheus.ipv4;
    inherit (links.prometheus) port;
    extraFlags = [ "--enable-feature=remote-write-receiver" ];
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

  systemd.services.loki.after = [ "wireguard-wgmesh.service" ];
  services.loki = {
    enable = true;
    dataDir = "/srv/storage/private/loki";
    configuration = {
      auth_enabled = false;
      server = {
        log_level = "warn";
        http_listen_address = loki-ingest.ipv4;
        http_listen_port = loki-ingest.port;
        grpc_listen_address = links.loki-grpc.ipv4;
        grpc_listen_port = links.loki-grpc.port;
      };
      frontend_worker.frontend_address = links.loki-grpc.tuple;
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
