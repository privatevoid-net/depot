{ cluster, config, depot, lib, pkgs, ... }:

let
  externalWays = lib.filterAttrs (_: cfg: !cfg.internal) cluster.config.ways;

  internalWays = lib.filterAttrs (_: cfg: cfg.internal) cluster.config.ways;

  byMode = lib.pipe cluster.config.ways [
    (lib.attrsToList)
    (lib.groupBy (way: way.value.mode))
    (lib.mapAttrs (n: v: lib.listToAttrs v))
  ];
in

{
  services.nginx = {
    virtualHosts = lib.mapAttrs' (name: cfg: {
      name = cfg.name;
      value = { ... }: {
        imports = [
          cfg.extras
          {
            listenAddresses = lib.mkIf cfg.internal [ config.reflection.interfaces.vstub.addr ];
            forceSSL = true;
            enableACME = !cfg.internal && !cfg.wildcard;
            useACMEHost = lib.mkMerge [
              (lib.mkIf cfg.internal cfg.domainSuffixInternal)
              (lib.mkIf cfg.wildcard "${name}.${cfg.domainSuffix}")
            ];
            locations = lib.mkMerge [
              {
                "/" = if cfg.mode == "static" then {
                  root = cfg.static {
                    inherit depot;
                    inherit pkgs;
                    inherit (pkgs) system;
                  };
                } else if cfg.grpc then {
                  extraConfig = ''
                    set $nix_proxy_grpc_target ${cfg.target};
                    grpc_pass $nix_proxy_grpc_target;
                  '';
                } else {
                  proxyPass = cfg.target;
                };
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

    appendHttpConfig = lib.mkIf (byMode.consul != {}) ''
      include /run/consul-template/nginx-ways-*.conf;
    '';
  };

  security.acme.certs = lib.mapAttrs' (name: cfg: {
    name = "${name}.${cfg.domainSuffix}";
    value = {
      domain = lib.mkIf cfg.wildcard "*.${name}.${cfg.domainSuffix}";
      dnsProvider = "exec";
      webroot = lib.mkForce null;
      group = "nginx";
    };
  }) externalWays;

  systemd.services = lib.mapAttrs' (name: cfg: {
    name = "acme-${name}.${cfg.domainSuffix}";
    value.distributed.enable = true;
  }) externalWays;

  services.consul-template.instances.ways = lib.mkIf (byMode.consul != {}) {
    user = "nginx";
    group = "nginx";
    settings = {
      consul.address = config.links.consulAgent.url;
      template = [
        {
          source = let
            upstreams = lib.mapAttrsToList (_: cfg: ''
              {{ if ne (len (service "${cfg.consulService}~_agent")) 0 }}
              # ${cfg.consulService}
              upstream ${cfg.nginxUpstreamName} {
                {{ range $i, $e := service "${cfg.consulService}~_agent" -}}
                server {{ .Address }}:{{ .Port }}{{ if ne $i 0 }} backup{{ end }};
                {{ end }}
              }
              {{ else }}
              # upstream ${cfg.nginxUpstreamName} (${cfg.consulService}): no servers available
              {{ end }}
            '') byMode.consul;
          in pkgs.writeText "ways-upstreams.ctmpl" (lib.concatStringsSep "\n" (lib.unique upstreams));
          destination = "/run/consul-template/nginx-ways-upstreams.conf";
          exec.command = lib.singleton (pkgs.writeShellScript "ways-reload" ''
            if ${config.systemd.package}/bin/systemctl is-active nginx.service; then
              exec ${config.services.nginx.package}/bin/nginx -s reload -g 'pid /run/nginx/nginx.pid;'
            fi
          '');
        }
      ];
    };
  };

  consul.services = {
    ways-proxy = {
      unit = "nginx";
      mode = "external";
      definition = {
        name = "ways-proxy";
        address = config.reflection.interfaces.primary.addrPublic;
        port = 443;
        checks = lib.singleton {
          interval = "60s";
          tcp = "127.0.0.1:80";
        };
        tags = lib.attrNames externalWays;
      };
    };
    ways-proxy-internal = {
      unit = "nginx";
      mode = "external";
      definition = {
        name = "ways-proxy-internal";
        address = config.reflection.interfaces.vstub.addr;
        port = 443;
        checks = lib.singleton {
          interval = "60s";
          tcp = "127.0.0.1:80";
        };
        tags = lib.attrNames internalWays;
      };
    };
  };
}
