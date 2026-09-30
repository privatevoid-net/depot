{ config, depot, lib, ... }:

{
  clan = {
    inherit (config.lib.hours) specialArgs;
    inventory = {
      machines = lib.mkMerge [
        (lib.mapAttrs (name: hour: {
          deploy = {
            targetHost = "root@${name}.${hour.enterprise.subdomain}.${depot.lib.meta.domain}";
            buildHost = lib.mkIf (hour.hardware.memory.gb < 4) "localhost";
          };
          tags = [ "light" ];
        }) config.gods.fromLight)
        (lib.mapAttrs (name: hour: {
          deploy.targetHost = "root@${name}.hyprspace";
          tags = [ "flesh" ];
        }) config.gods.fromFlesh)
      ];
    };
  };
}
