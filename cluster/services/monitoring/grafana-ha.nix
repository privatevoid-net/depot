{ cluster, config, depot, lib, pkgs, tools, ... }:
let
  inherit (tools.meta) domain;

  inherit (cluster.config.links) loki-ingest prometheus-ingest;

  inherit (cluster.config) hostLinks;

  inherit (config.networking) hostName;

  svc = cluster.config.services.monitoring;

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
    package = depot.packages.grafana;
    dataDir = "/srv/storage/private/grafana";
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
          inherit (loki-ingest) url;
          type = "loki";
        }
      ];
    };
  };

  systemd.services = {
    grafana = {
      enable = false;
      serviceConfig.EnvironmentFile = config.age.secrets.grafana-secrets.path;
    };
    grafana-ha = let
      base = config.systemd.services.grafana;
      inherit (config.services) consul;
      svc = config.consul.services.grafana;
      run = pkgs.writeShellScript "grafana-ha-start" ''
        trap '${svc.commands.deregister}' EXIT
        ${svc.commands.register}
        ${base.serviceConfig.ExecStart}
      '';
    in {
      inherit (base) wantedBy;
      description = "Grafana | High Availability";
      aliases = [ "grafana.service" ];

      after = base.after ++ [ "consul.service" ];
      requires = [ "consul.service" ];

      serviceConfig = base.serviceConfig // {
        ExecStart = "${consul.package}/bin/consul lock --shell=false services/grafana ${run}";
        # consul uses AF_NETLINK to determine interface addresses, even when just registering a service
        RestrictAddressFamilies = base.serviceConfig.RestrictAddressFamilies ++ [ "AF_NETLINK" ];
      };
    };
  };

  services.nginx = {
    upstreams.grafana-ha.servers = lib.mapAttrs' (_: links: lib.nameValuePair links.grafana.tuple {}) (lib.getAttrs (svc.nodes.grafana) hostLinks);

    virtualHosts."monitoring.${domain}" = lib.recursiveUpdate (tools.nginx.vhosts.proxy "http://grafana-ha") {
      locations."/".proxyWebsockets = true;
    };
  };

  security.acme.certs."monitoring.${domain}" = {
    dnsProvider = "pdns";
    webroot = lib.mkForce null;
  };

  consul.services.grafana = {
    mode = "manual";
    unit = "grafana-ha";
    definition = rec {
      name = "grafana";
      address = depot.reflection.interfaces.primary.addrPublic;
      port = 443;
      checks = [
        {
          name = "Frontend";
          id = "service:grafana:frontend";
          interval = "30s";
          http = "https://${address}";
          tls_server_name = "monitoring.${domain}";
          method = "HEAD";
        }
        {
          name = "Backend";
          id = "service:grafana:backend";
          interval = "5s";
          http = "${hostLinks.${hostName}.grafana.url}/healthz";
        }
      ];
    };
  };
}