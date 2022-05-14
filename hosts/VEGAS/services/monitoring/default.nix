{ config, hosts, lib, tools, ... }:
let
  inherit (tools.meta) domain;

  inherit (config) ports portsStr;

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
in
{
  age.secrets.grafana-secrets = {
    file = ../../../../secrets/grafana-secrets.age;
  };

  reservePortsFor = [ "grafana" "prometheus" ];
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
}
