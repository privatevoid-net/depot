{ config, depot, lib, ... }:

{
  clan = {
    inherit (config.lib.hours) specialArgs;
    inventory = {
      machines = lib.mapAttrs (name: hour: {
        deploy.targetHost = "root@${name}.${hour.enterprise.subdomain}.${depot.lib.meta.domain}";
        tags = [ "light" ];
      }) config.gods.fromLight;
    };
  };
}
