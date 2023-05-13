{ config, pkgs, ... }:

{
  systemd = {
    timers.searx-proxy-shuffle = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        AccuracySec = "5m";
        RandomizedDelaySec = "10m";
        OnCalendar = "*:15,45";
      };
    };
    services.searx-proxy-shuffle = {
      after = [ "searx-init.service" ];
      path = with pkgs; [ curl jq ];
      script = ''
        umask 77
        test -e /run/searx/settings.yml || exit 0

        if ! curl -fsSL -D /run/searx/proxy-shuffle-curl-status.txt https://api-www.mullvad.net/www/relays/wireguard/ > /run/searx/proxylist-new.json; then
          echo "Failed to get new proxy list"
          cat /run/searx/proxy-shuffle-curl-status.txt
          exit 1
        fi

        jq < /run/searx/proxylist-new.json \
          '.[] | select(.active) | select(.country_code as $cc | ["es","se","rs","ch","ro"] | index($cc)) | "socks5://\(.socks_name):\(.socks_port)"' \
          | shuf > /run/searx/proxies.ndjson

        jq --slurpfile proxies /run/searx/proxies.ndjson < /run/searx/settings.yml > /run/searx/.settings-new.yml \
          '.outgoing.proxies.http=$proxies | .outgoing.proxies.https=$proxies'

        mv /run/searx/.settings-new.yml /run/searx/settings.yml
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "searx";
        Group = "searx";
        ExecStartPost = "+${config.systemd.package}/bin/systemctl try-reload-or-restart uwsgi.service";
      };
    };
  };
}
