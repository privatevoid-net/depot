{ cluster, config, lib, ... }:

{
  nix.settings.substituters = lib.pipe cluster.config.hostLinks [
    (lib.filterAttrs (name: value: value ? builderCache && name != config.networking.hostName))
    (lib.mapAttrsToList (_: value: "${value.builderCache.url}?priority=50"))
  ];
}
