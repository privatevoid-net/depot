{ cluster, config, depot, lib, pkgs, ... }:

let
  inherit (depot.lib.meta) domain;

  externalWays = lib.filterAttrs (_: cfg: !cfg.internal) cluster.config.ways;

  consulServiceWays = lib.filterAttrs (_: cfg: cfg.useConsul) cluster.config.ways;

  consulHttpAddr = "${config.services.consul.extraConfig.addresses.http or "127.0.0.1"}:${toString (config.services.consul.extraConfig.ports.http or 8500)}";
in

{
  services.nginx = {
    virtualHosts = lib.mapAttrs' (name: cfg: {
      name = if cfg.internal then "${name}.internal.${domain}" else "${name}.${domain}";
      value = { ... }: {
        imports = [
          cfg.extras
          {
            forceSSL = true;
            enableACME = !cfg.internal;
            useACMEHost = lib.mkIf cfg.internal "internal.${domain}";
            locations = lib.mkMerge [
              {
                "/".proxyPass = cfg.target;
                "${cfg.healthCheckPath}".extraConfig = "access_log off;";
              }
              {
                "/.well-known/ways/internal-health-check" = {
                  return = ''200 "INTERNAL_OK\n"'';
                  extraConfig = "access_log off;";
                };
              }
            ];
          }
        ];
      };
    }) cluster.config.ways;

    appendHttpConfig = lib.mkIf (consulServiceWays != {}) ''
      include /run/consul-template/nginx-ways-*.conf;
    '';
  };

  security.acme.certs = lib.mapAttrs' (name: cfg: {
    name = "${name}.${domain}";
    value = {
      dnsProvider = "exec";
      webroot = lib.mkForce null;
    };
  }) externalWays;

  services.consul-template.instances.ways = lib.mkIf (consulServiceWays != {}) {
    user = "nginx";
    group = "nginx";
    settings = {
      consul.address = "http://${consulHttpAddr}";
      template = [
        {
          source = let
            upstreams = lib.mapAttrsToList (_: cfg: ''
              upstream ${cfg.nginxUpstreamName} {
                {{ range $i, $e := service "${cfg.consulService}~_agent" -}}
                server {{ .Address }}:{{ .Port }}{{ if ne $i 0 }} backup{{ end }};
                {{end}}
              }
            '') consulServiceWays;
          in pkgs.writeText "ways-upstreams.ctmpl" (lib.concatStringsSep "\n" upstreams);
          destination = "/run/consul-template/nginx-ways-upstreams.conf";
          exec.command = [
            "${config.services.nginx.package}/bin/nginx"
            "-s" "reload"
            "-g" "pid /run/nginx/nginx.pid;"
          ];
        }
      ];
    };
  };

  consul.services.ways-proxy = {
    unit = "nginx";
    mode = "external";
    definition = {
      name = "ways-proxy";
      address = depot.reflection.interfaces.primary.addrPublic;
      port = 443;
      checks = lib.singleton {
        interval = "60s";
        tcp = "127.0.0.1:80";
      };
      tags = lib.attrNames externalWays;
    };
  };
}
