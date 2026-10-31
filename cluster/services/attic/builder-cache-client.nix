{ cluster, config, lib, ... }:

{
  services.ncro.instances.internal.settings.upstreams = lib.pipe cluster.config.hostLinks [
    (lib.filterAttrs (name: value: value ? builderCache && name != config.networking.hostName))
    (lib.mapAttrsToList (_: value: {
      inherit (value.builderCache) url;
      priority = 50;
    }))
  ];
}
