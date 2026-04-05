{ cluster, config, depot, ... }:

let
  inherit (depot.lib.meta) domain;
  link = cluster.config.hostLinks.${config.networking.hostName}.notify;
in

{
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://notify.${domain}";
      listen-http = link.tuple;
    };
  };

  systemd.services.ntfy-sh.distributed = {
    enable = true;
    registerService = "ntfy";
  };

  consul.services.ntfy = {
    mode = "manual";
    unit = "ntfy-sh";
    definition = {
      name = "ntfy";
      address = link.ipv4;
      inherit (link) port;
      checks = [
        {
          name = "ntfy";
          id = "service:ntfy:backend";
          interval = "5s";
          http = "${link.url}/v1/health";
        }
      ];
    };
  };
}
