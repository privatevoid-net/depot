{ depot, lib, ... }:

let
  tools = (depot.lib.override {
    meta.domain = lib.mkForce "cdn-shield.privatevoid.net";
  }).nginx;
in
{
  services.nginx.virtualHosts = tools.mappers.mapSubdomains (import ./shields.nix { inherit tools; });
  services.nginx.appendHttpConfig = ''
    proxy_cache_path /var/cache/nginx/wttr levels=1:2 keys_zone=wttr:10m max_size=100m inactive=30d use_temp_path=off;
  '';
}
