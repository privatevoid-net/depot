{ config, lib, ... }:

with lib;

let
  cfg = config.consul;

  consul = "${config.services.consul.package}/bin/consul";

  consulServiceDefinition = submodule ({ name, ... }: {
    unit = mkOption {
      description = "Which systemd service to attach to.";
      default = name;
      type = types.str;
    };
    definition = mkOption {
      description = "Consul service definition.";
      type = types.attrs;
    };
  });

  attachToService = name: conf: let
    serviceJson = pkgs.writeText "consul-service-${name}.json" (builtins.toJSON conf.definition);
  in {
    name = conf.unit;
    value = {
      serviceConfig = {
        ExecStartPost = "${consul} services register ${serviceJson}";
        ExecStopPre = "${consul} services deregister ${serviceJson}";
      };
    };
  };
in

{
  options.consul = {
    services = mkOption {
      type = with types; attrsOf consulServiceDefinition;
      default = {};
    };
  };

  config = lib.mkIf (cfg.services != {}) {
    systemd.services = mapAttrs' attachToService cfg.services;
    warnings = optional (!config.services.consul.enable) "Consul service registrations found, but Consul agent is not enabled on this machine.";
  };
}
