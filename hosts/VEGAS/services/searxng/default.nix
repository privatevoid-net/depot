{ config, inputs, lib, pkgs, tools, ... }:
let
  port = config.portsStr.searxng;
in
{
  reservePortsFor = [ "searxng" ];

  age.secrets.searxng-secrets.file = ../../../../secrets/searxng-secrets.age;
  services.searx = {
    enable = true;
    runInUwsgi = true;
    package = inputs.self.packages.${pkgs.system}.searxng;
    environmentFile = config.age.secrets.searxng-secrets.path;
    settings = {
      server = {
        secret_key = "@SEARXNG_SECRET@";
      };
    };
    uwsgiConfig = {
      http = "127.0.0.1:${port}";
      cache2 = "name=searxcache,items=2000,blocks=2000,blocksize=65536,bitmap=1";
      buffer-size = 65536;
      env = ["SEARXNG_SETTINGS_PATH=/run/searx/settings.yml"];
      disable-logging = true;
    };
  };
  services.nginx.virtualHosts."search.${tools.meta.domain}" = lib.recursiveUpdate (tools.nginx.vhosts.proxy "http://127.0.0.1:${port}") {
    extraConfig = "access_log off;";
  };
}
