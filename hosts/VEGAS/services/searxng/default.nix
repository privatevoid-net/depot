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
      outgoing.proxies = rec {
        http = [
            "socks5://es1-wg.socks5.mullvad.net:1080"
            "socks5://ch10-wg.socks5.mullvad.net:1080"
            "socks5://rs4-wg.socks5.mullvad.net:1080"
            "socks5://ro4-wg.socks5.mullvad.net:1080"
            "socks5://ch13-wg.socks5.mullvad.net:1080"
            "socks5://es2-wg.socks5.mullvad.net:1080"
            "socks5://ro5-wg.socks5.mullvad.net:1080"
            "socks5://rs3-wg.socks5.mullvad.net:1080"
            "socks5://ch21-wg.socks5.mullvad.net:1080"
            "socks5://es4-wg.socks5.mullvad.net:1080"
            "socks5://ch2-wg.socks5.mullvad.net:1080"
            "socks5://ro6-wg.socks5.mullvad.net:1080"
            "socks5://es5-wg.socks5.mullvad.net:1080"
            "socks5://ch16-wg.socks5.mullvad.net:1080"
            "socks5://ch6-wg.socks5.mullvad.net:1080"
            "socks5://es6-wg.socks5.mullvad.net:1080"
            "socks5://ro7-wg.socks5.mullvad.net:1080"
            "socks5://es7-wg.socks5.mullvad.net:1080"
        ];
        https = http;
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
  systemd.services.uwsgi.after = [ "wireguard-wgmv-es7.service" "network-addresses-wgmv-es7.service" ];
}
