{ config, lib, ... }:
with lib;

let
  getHostConfigurations = hostName: svcConfig:
    lib.mapAttrsToList (groupName: _: svcConfig.nixos.${groupName})
    (lib.filterAttrs (_: lib.elem hostName) svcConfig.nodes);


  introspectionModule._module.args.cluster = {
    inherit (config) vars;
    inherit config;
  };
in

{
  options.services = mkOption {
    description = "Cluster services.";
    type = with types; attrsOf (submodule ./service-module.nix);
    default = {};
  };

  config.out.injectNixosConfig = hostName: (lib.flatten (lib.mapAttrsToList (_: getHostConfigurations hostName) config.services)) ++ [
    introspectionModule
  ];
}
