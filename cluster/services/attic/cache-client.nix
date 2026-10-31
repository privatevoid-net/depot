{ config, depot, ... }:

{
  imports = [
    depot.inputs.ncro.nixosModules.ncro
  ];

  links.ncroInternal = {
    useRandomAddr = true;
    port = 80;
    protocol = "http";
  };

  networking.hosts."${config.links.ncroInternal.ipv4}" = [
    "cache.internal"
  ];

  services.ncro = {
    enable = true;
    instances = {
      internal.settings = {
        server = {
          listen = config.links.ncroInternal.tuple;
          cache_priority = 10;
        };
      };
    };
  };

  systemd.services."ncro@internal" = {
    overrideStrategy = "asDropin";
    serviceConfig = {
      CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
    };
  };

  nix.settings.substituters = [ "http://cache.internal" ];
}
