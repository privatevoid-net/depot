{ cluster, depot, lib, ... }:

let
  inherit (depot.lib.meta) domain;

  externalWays = lib.filterAttrs (_: cfg: !cfg.internal) cluster.config.ways;
in

{
  services.nginx.virtualHosts = lib.mapAttrs' (name: cfg: {
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

  security.acme.certs = lib.mapAttrs' (name: cfg: {
    name = "${name}.${domain}";
    value = {
      dnsProvider = "exec";
      webroot = lib.mkForce null;
    };
  }) externalWays;

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
