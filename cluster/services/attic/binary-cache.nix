{ config, cluster, depot, lib, ... }:
with depot.lib.nginx;
{
  imports = [
    depot.inputs.ncro.nixosModules.ncro
  ];

  links = {
    ncroDefault.protocol = "http";
    ncroManicSystems.protocol = "http";
  };

  security.acme.certs = {
    "cache.${depot.lib.meta.domain}" = {
      dnsProvider = "exec";
      webroot = lib.mkForce null;
    };
    "cache.manic.systems" = {
      dnsProvider = "exec";
      webroot = lib.mkForce null;
    };
  };

  services.ncro = {
    enable = true;
    instances = {
      default.settings = {
        server = {
          listen = config.links.ncroDefault.tuple;
          cache_priority = 45;
        };
        upstreams = [
          {
            url = "https://cache-api.${depot.lib.meta.domain}/nix-store";
            priority = 45;
          }
        ];
      };
      manic-systems.settings = {
        server = {
          listen = config.links.ncroManicSystems.tuple;
          cache_priority = 50;
        };
        upstreams = [
          {
            url = "https://circus-cache-ndkyblidbo7zphxq38qq169tvs6ifjkg.fsn1.your-objectstorage.com";
            priority = 50;
          }
          {
            url = "https://ci.manic.systems/nix-cache";
            priority = 60;
          }
        ];
      };
    };
  };

  services.nginx.upstreams = {
      nar-serve.extraConfig = ''
      random;
      server ${config.links.nar-serve-self.tuple} fail_timeout=0;
      server ${config.links.nar-serve-nixos-org.tuple} fail_timeout=0;
    '';
  };
  services.nginx.virtualHosts = {
    "cache.${depot.lib.meta.domain}" = vhosts.basic // {
      locations = {
        "= /".return = "302 /404";
        "/".proxyPass = config.links.ncroDefault.url;
        "/nix/store" = {
          proxyPass = "http://nar-serve";
          extraConfig = ''
            proxy_next_upstream error http_500 http_404;
          '';
        };
      };
    };
    "cache.manic.systems" = vhosts.basic // {
      locations = {
        "= /".return = "302 /404";
        "/".proxyPass = config.links.ncroManicSystems.url;
      };
    };
  };
}
