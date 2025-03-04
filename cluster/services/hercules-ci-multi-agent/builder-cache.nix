{ cluster, config, depot, pkgs, ... }:

let
  link = cluster.config.hostLinks.${config.networking.hostName}.builderCache;
  linkLocal = config.links.builderCache;
in
{
  links.builderCache.protocol = "http";

  services.nginx.virtualHosts.${link.hostname} = depot.lib.nginx.vhosts.proxy linkLocal.url;

  services.nix-serve = {
    enable = true;
    package = pkgs.nix-serve-ng;
    bindAddress = linkLocal.ipv4;
    inherit (linkLocal) port;
    secretKeyFile = cluster.config.services.hercules-ci-multi-agent.secrets.cacheSigningKey.path;
    extraParams = "--priority 50";
  };
}
