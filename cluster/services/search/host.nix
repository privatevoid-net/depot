{ cluster, config, depot, lib, ... }:
let
  inherit (config) links;
  torProxyEngine = { name, domain }: {
    inherit name;
    shortcut = name;
    engine = "xpath";
    search_url = "http://${domain}/search?q={query}&pageno={pageno}&lang=en";
    paging = true;
    title_xpath = "//article/h3/a";
    content_xpath = "//article/p";
    url_xpath = "//article/a/@href";
    enable_http = true;
  };
in
{
  links.searxng.protocol = "http";

  services.searx = {
    enable = true;
    configureUwsgi = true;
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
        (torProxyEngine {
          name = "rhscz";
          domain = "ls67zxncmcqgn2vg74ckcwxgu5p3e5mf2khues3egkumhcqtbsg4kqyd.onion";
        })
        (torProxyEngine {
          name = "oloke";
          domain = "searxokthnxmo7ndis35jpts2tawcwvbovuy47qtavwo7oq4jgcm5gqd.onion";
        })
        (torProxyEngine {
          name = "anoninet";
          domain = "search.anoninetru5tflukgfaehun7q6khowgmymcff3gtk5oyesqazhmfxtyd.onion";
        })
        (torProxyEngine {
          name = "serpensin";
          domain = "searxngorpgnztkcftpz3ycdpyajd4q55y2nejw3tbszocht5zdh4lyd.onion";
        })
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
