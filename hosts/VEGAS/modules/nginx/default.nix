{ lib, config, tools, ... }:

let
  inherit (tools.meta) domain adminEmail;
in
  with tools.nginx.vhosts;
  with tools.nginx.mappers;
{
  security.acme.email = adminEmail;
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
}
