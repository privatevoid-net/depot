{ config, cluster, depot, ... }:
with depot.lib.nginx;
let
  addrSplit' = builtins.split ":" config.services.minio.listenAddress;
  addrSplit = builtins.filter builtins.isString addrSplit';
  host' = builtins.head addrSplit;
  host = if host' == "" then "127.0.0.1" else host';
  port = builtins.head (builtins.tail addrSplit);
in
{
  links.garageNixStoreInternalRedirect = {
    protocol = "http";
    path = "/nix-store";
  };
  services.nginx.upstreams = {
      nar-serve.extraConfig = ''
      random;
      server ${config.links.nar-serve-self.tuple} fail_timeout=0;
      server ${config.links.nar-serve-nixos-org.tuple} fail_timeout=0;
    '';
    nix-store.servers = {
      "${config.links.atticServer.tuple}" = {
        fail_timeout = 0;
      };
      "${config.links.garageNixStoreInternalRedirect.tuple}" = {
        fail_timeout = 0;
      };
      "${host}:${port}" = {
        fail_timeout = 0;
        backup = true;
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
          proxyPass = "http://nix-store/nix-store$request_uri";
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
      locations."~ ^${config.links.garageNixStoreInternalRedirect.path}/(.*)" = {
        proxyPass = with cluster.config.links.garageWeb; "${protocol}://nix-store.${hostname}/$1";
        recommendedProxySettings = false;
        extraConfig = ''
          proxy_set_header Host "nix-store.${cluster.config.links.garageWeb.hostname}";
        '';
      };
    };
  };
}
