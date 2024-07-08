{ cluster, config, depot, lib, ... }:
let
  inherit (config) links;
in
{
  links.searxng.protocol = "http";

  services.searx = {
    enable = true;
    runInUwsgi = true;
    package = depot.packages.searxng;
    environmentFile = cluster.config.services.search.secrets.default.path;
    settings = {
      server = {
        secret_key = "@SEARXNG_SECRET@";
      };
      search.formats = [
        "html"
        "json"
      ];
      engines = [
        { name = "bing"; disabled = true; }
        { name = "brave"; disabled = true; }
      ];
      ui.theme_args.simple_style = "dark";
      outgoing = {
        using_tor_proxy = true;
        proxies = rec {
          http = [ config.links.torSocks.url ];
          https = http;
        };
      };
    };
    uwsgiConfig = {
      http = links.searxng.tuple;
      cache2 = "name=searxcache,items=2000,blocks=2000,blocksize=65536,bitmap=1";
      buffer-size = 65536;
      disable-logging = true;
    };
  };
  services.nginx.virtualHosts."search.${depot.lib.meta.domain}" = lib.recursiveUpdate (depot.lib.nginx.vhosts.proxy links.searxng.url) {
    extraConfig = "access_log off;";
  };
  systemd.services.uwsgi.after = [ "tor.service" ];
}
