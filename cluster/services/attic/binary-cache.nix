{ config, cluster, depot, lib, ... }:
with depot.lib.nginx;
{
  imports = [
    depot.inputs.ncro.nixosModules.ncro
  ];

  links.ncro.protocol = "http";

  security.acme.certs."cache.${depot.lib.meta.domain}" = {
    dnsProvider = "exec";
    webroot = lib.mkForce null;
  };

  services.ncro = {
    enable = true;
    settings = {
      server = {
        listen = config.links.ncro.tuple;
        cache_priority = 45;
      };
      upstreams = [
        {
          url = "https://cache-api.${depot.lib.meta.domain}/nix-store";
          priority = 45;
        }
      ];
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
        "/".proxyPass = config.links.ncro.url;
        "/nix/store" = {
          proxyPass = "http://nar-serve";
          extraConfig = ''
            proxy_next_upstream error http_500 http_404;
          '';
        };
      };
    };
  };
}
