{ config, depot, ... }:

{
  services.notify = {
    nodes.server = [ "grail" "prophet" ];
    nixos.server = ./server.nix;
    meshLinks.server.notify.link.protocol = "http";
  };

  ways = config.lib.forService "notify" {
    notify = {
      consulService = "ntfy";
      extras.locations."/".proxyWebsockets = true;
    };
  };

  monitoring.blackbox.targets.notify = config.lib.forService "notify" {
    address = "https://notify.${depot.lib.meta.domain}/v1/health";
    module = "https2xx";
  };
}
