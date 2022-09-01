{ lib, config, tools, ... }:

let
  inherit (tools.meta) adminEmail;
in {
  security.acme.defaults.email = adminEmail;
  security.acme.acceptTerms = true;
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    proxyResolveWhileRunning = false;
    resolver = {
      addresses = [ "127.0.0.1" ];
      valid = "30s";
    };
    appendHttpConfig = ''
      server_names_hash_bucket_size 128;
      proxy_headers_hash_max_size 4096;
      proxy_headers_hash_bucket_size 128;
      log_format fmt_loki 'host=$host remote_addr=$remote_addr remote_user=$remote_user request="$request" status=$status body_bytes_sent=$body_bytes_sent http_referer="$http_referer" http_user_agent="$http_user_agent"';
      access_log syslog:server=unix:/dev/log,tag=nginx_access,nohostname fmt_loki;
    '';
  };
  services.phpfpm.pools.www = {
    inherit (config.services.nginx) user group;
    settings = {
      pm = "ondemand";
      "pm.max_children" = 16;
      "listen.owner" = config.services.nginx.user;
      "listen.group" = config.services.nginx.group;
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  systemd.services.nginx.after = [ "network-online.target" ];
}
