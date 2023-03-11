{ config, depot, lib, tools, ... }:
let
  inherit (config) links;
in
{
  links.searxng.protocol = "http";

  age.secrets.searxng-secrets.file = ../../../../secrets/searxng-secrets.age;
  services.searx = {
    enable = true;
    runInUwsgi = true;
    package = depot.packages.searxng;
    environmentFile = config.age.secrets.searxng-secrets.path;
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
      outgoing.proxies = rec {
        http = [
            "socks5://es-mad-wg-socks5-102.relays.mullvad.net:1080"
            "socks5://ch-zrh-wg-socks5-403.relays.mullvad.net:1080"
            "socks5://ro-buh-wg-socks5-001.relays.mullvad.net:1080"
            "socks5://es-mad-wg-socks5-101.relays.mullvad.net:1080"
            "socks5://ro-buh-wg-socks5-002.relays.mullvad.net:1080"
            "socks5://rs-beg-wg-socks5-001.relays.mullvad.net:1080"
            "socks5://ch5-wg.socks5.mullvad.net:1080"
            "socks5://ch-zrh-wg-socks5-501.relays.mullvad.net:1080"
            "socks5://rs4-wg.socks5.mullvad.net:1080"
            "socks5://ch-zrh-wg-socks5-404.relays.mullvad.net:1080"
            "socks5://es-mad-wg-socks5-201.relays.mullvad.net:1080"
            "socks5://ch-zrh-wg-socks5-502.relays.mullvad.net:1080"
            "socks5://ch-zrh-wg-socks5-506.relays.mullvad.net:1080"
            "socks5://es-mad-wg-socks5-202.relays.mullvad.net:1080"
        ];
        https = http;
      };
    };
    uwsgiConfig = {
      http = links.searxng.tuple;
      cache2 = "name=searxcache,items=2000,blocks=2000,blocksize=65536,bitmap=1";
      buffer-size = 65536;
      env = ["SEARXNG_SETTINGS_PATH=/run/searx/settings.yml"];
      disable-logging = true;
    };
  };
  services.nginx.virtualHosts."search.${tools.meta.domain}" = lib.recursiveUpdate (tools.nginx.vhosts.proxy links.searxng.url) {
    extraConfig = "access_log off;";
  };
  systemd.services.uwsgi.after = [ "wireguard-wgmv.service" "network-addresses-wgmv.service" ];
}
