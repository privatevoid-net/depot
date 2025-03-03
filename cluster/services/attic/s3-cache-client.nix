{ cluster, ... }:

{
  nix.settings.substituters = [ "https://nix-store.${cluster.config.links.garageWeb.hostname}?priority=60" ];
}
