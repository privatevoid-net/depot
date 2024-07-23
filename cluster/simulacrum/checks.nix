{ config, extendModules, lib, ... }:

{
  perSystem = { pkgs, ... }: {
    checks = lib.mapAttrs' (name: svc: let
      runSimulacrum = pkgs.callPackage ./. {
        inherit config extendModules;
      };
    in {
      name = "simulacrum-${name}";
      value = runSimulacrum {
        service = name;
      };
    }) (lib.filterAttrs (_: svc: svc.simulacrum.enable) config.cluster.config.services);
  };
}
