{ config, cluster, depot, lib, ... }:
with depot.lib.nginx;
{
  links = {
    atticNixStoreInternalRedirect.protocol = "http";
    garageNixStoreInternalRedirect.protocol = "http";
  };

  security.acme.certs."cache.${depot.lib.meta.domain}" = {
    dnsProvider = "exec";
    webroot = lib.mkForce null;
  };

  services.nginx.upstreams = {
      nar-serve.extraConfig = ''
      random;
      server ${config.links.nar-serve-self.tuple} fail_timeout=0;
      server ${config.links.nar-serve-nixos-org.tuple} fail_timeout=0;
    '';
    nix-store.servers = {
      "${config.links.garageNixStoreInternalRedirect.tuple}" = {
        fail_timeout = 0;
      };
      "${config.links.atticNixStoreInternalRedirect.tuple}" = {
        fail_timeout = 0;
      };
    };
  };
  services.nginx.appendHttpConfig = ''
    proxy_cache_path /var/cache/nginx/nixstore levels=1:2 keys_zone=nixstore:10m max_size=10g inactive=24h use_temp_path=off;
  '';
  services.nginx.virtualHosts = {
    "cache.${depot.lib.meta.domain}" = vhosts.basic // {
      locations = {
        "= /".return = "302 /404";
        "/" = {
          proxyPass = "http://nix-store";
          extraConfig = ''
            proxy_next_upstream error http_500 http_502 http_404;
          '';
        };
        "/nix/store" = {
          proxyPass = "http://nar-serve";
          extraConfig = ''
            proxy_next_upstream error http_500 http_404;
          '';
        };
      };
      extraConfig = ''
        proxy_cache nixstore;
        proxy_cache_use_stale error timeout http_500 http_502;
        proxy_cache_lock on;
        proxy_cache_key $request_uri;
        proxy_cache_valid 200 24h;
      '';
    };
    "garage-nix-store.internal.${depot.lib.meta.domain}" = {
      serverName = "127.0.0.1";
      listen = [
        {
          addr = "127.0.0.1";
          inherit (config.links.garageNixStoreInternalRedirect) port;
        }
      ];
      locations."/" = {
        proxyPass = with cluster.config.links.garageWeb; "${protocol}://nix-store.${hostname}";
        recommendedProxySettings = false;
        extraConfig = ''
          proxy_set_header Host "nix-store.${cluster.config.links.garageWeb.hostname}";
        '';
      };
    };
    "attic-nix-store.internal.${depot.lib.meta.domain}" = {
      serverName = "127.0.0.1";
      listen = [
        {
          addr = "127.0.0.1";
          inherit (config.links.atticNixStoreInternalRedirect) port;
        }
      ];
      locations."/" = {
        proxyPass = "https://cache-api.${depot.lib.meta.domain}/nix-store$request_uri";
        recommendedProxySettings = false;
        extraConfig = ''
          proxy_set_header Host "cache-api.${depot.lib.meta.domain}";
        '';
      };
    };
  };
}
