{ config, lib, ... }:
with lib;

let
  getHostConfigurations = hostName: svcName: svcConfig: let
    serviceConfigs =
      lib.mapAttrsToList (groupName: _: svcConfig.nixos.${groupName})
      (lib.filterAttrs (_: lib.elem hostName) svcConfig.nodes);

    secretsConfig = let
      secrets = lib.filterAttrs (_: secret: lib.any (node: node == hostName) secret.nodes) svcConfig.secrets;
    in {
      age.secrets = lib.mapAttrs' (secretName: secretConfig: {
        name = "cluster-${svcName}-${secretName}";
        value = {
          inherit (secretConfig) path mode owner group;
          file = ../secrets/${svcName}-${secretName}${lib.optionalString (!secretConfig.shared) "-${hostName}"}.age;
        };
      }) secrets;

      systemd.services = lib.mkMerge (lib.mapAttrsToList (secretName: secretConfig: lib.genAttrs secretConfig.services (systemdServiceName: {
        restartTriggers = [ "${../secrets/${svcName}-${secretName}${lib.optionalString (!secretConfig.shared) "-${hostName}"}.age}" ];
      })) secrets);
    };
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
