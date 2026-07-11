{ cluster, config, depot, pkgs, ... }:

let
  link = cluster.config.hostLinks.${config.networking.hostName}.builderCache;
  linkLocal = config.links.builderCache;
in
{
  links.builderCache.protocol = "http";

  services.nginx.virtualHosts.${link.hostname} = depot.lib.nginx.vhosts.proxy linkLocal.url;

  services.harmonia.cache = {
    enable = true;
    signKeyPaths = [ cluster.config.services.hercules-ci-multi-agent.secrets.cacheSigningKey.path ];
    settings = {
      bind = linkLocal.tuple;
      enable_compression = true;
      priority = 50;
    };
  };
}
