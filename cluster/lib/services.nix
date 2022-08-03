{ config, lib, ... }:
with lib;

let
  getHostConfigurations = svcConfig: hostName:
    lib.mapAttrsToList (groupName: _: svcConfig.nixos.${groupName})
    (lib.filterAttrs (_: v: lib.elem hostName v) svcConfig.nodes);

  getServiceConfigurations = svcConfig: getHostConfigurations svcConfig config.vars.hostName;
in

{
  options.services = mkOption {
    description = "Cluster services.";
    type = with types; attrsOf (submodule (import ./service-module.nix config.vars));
    default = {};
  };
  config.out.injectedNixosConfig = lib.flatten (lib.mapAttrsToList (_: getServiceConfigurations) config.services);
}
