{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.consul;

  consul = "${config.services.consul.package}/bin/consul";

  consulServiceDefinition = types.submodule ({ name, ... }: {
    options = {
      unit = mkOption {
        description = "Which systemd service to attach to.";
        default = name;
        type = types.str;
      };
      mode = mkOption {
        description = "How to attach command executions to the service.";
        type = types.enum [ "direct" "external" ];
        default = "direct";
      };
      definition = mkOption {
        description = "Consul service definition.";
        type = types.attrs;
      };
    };
  });

  attachToService = name: conf: let
    serviceJson = pkgs.writeText "consul-service-${name}.json" (builtins.toJSON conf.definition);
  in {
    name = {
      direct = conf.unit;
      external = "register-consul-svc-${conf.unit}";
    }.${conf.mode};
    value = {
      direct = {
        serviceConfig = {
          ExecStartPost = "${consul} services register ${serviceJson}";
          ExecStopPost = "${consul} services deregister ${serviceJson}";
        };
      };
      external = {
        after = [ "${conf.unit}.service" ];
        wantedBy = [ "${conf.unit}.service" ];
        unitConfig.BindsTo = "${conf.unit}.service";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${consul} services register ${serviceJson}";
          ExecStop = "${consul} services deregister ${serviceJson}";
        };
      };
    }.${conf.mode};
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
