{ config, lib, ... }:
with lib;

let
  getHostConfigurations = hostName: svcName: svcConfig: let
    serviceConfigs =
      lib.mapAttrsToList (groupName: _: svcConfig.nixos.${groupName})
      (lib.filterAttrs (_: lib.elem hostName) svcConfig.nodes);

    secretsConfig.age.secrets = lib.mapAttrs' (secretName: secretConfig: {
      name = "cluster-${svcName}-${secretName}";
      value = {
        inherit (secretConfig) path mode owner group;
        file = ../secrets/${svcName}-${secretName}${lib.optionalString (!secretConfig.shared) "-${hostName}"}.age;
      };
    }) (lib.filterAttrs (_: secret: lib.any (node: node == hostName) secret.nodes) svcConfig.secrets);
  in serviceConfigs ++ [
    secretsConfig
  ];

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

  config.out.injectNixosConfig = hostName: (lib.flatten (lib.mapAttrsToList (getHostConfigurations hostName) config.services)) ++ [
    introspectionModule
  ];
}
