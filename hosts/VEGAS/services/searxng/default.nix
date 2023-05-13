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
            "socks5://se-got-wg-socks5-001.relays.mullvad.net:1080"
            "socks5://se-sto-wg-socks5-010.relays.mullvad.net:1080"
            "socks5://se-sto-wg-socks5-014.relays.mullvad.net:1080"
            "socks5://ch-zrh-wg-socks5-005.relays.mullvad.net:1080"
            "socks5://se-mma-wg-socks5-001.relays.mullvad.net:1080"
            "socks5://se-mma-wg-socks5-101.relays.mullvad.net:1080"
            "socks5://se-mma-wg-socks5-102.relays.mullvad.net:1080"
            "socks5://se-mma-wg-socks5-103.relays.mullvad.net:1080"
            "socks5://ch-zrh-wg-socks5-002.relays.mullvad.net:1080"
            "socks5://se-sto-wg-socks5-004.relays.mullvad.net:1080"
            "socks5://se-got-wg-socks5-003.relays.mullvad.net:1080"
            "socks5://se-sto-wg-socks5-006.relays.mullvad.net:1080"
            "socks5://se-sto-wg-socks5-008.relays.mullvad.net:1080"
            "socks5://se-sto-wg-socks5-001.relays.mullvad.net:1080"
            "socks5://se-mma-wg-socks5-004.relays.mullvad.net:1080"
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
