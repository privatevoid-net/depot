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

  attachToService = unit: servicesRaw: let
    services = map (getAttr "definition") servicesRaw;
    servicesJson = pkgs.writeText "consul-services-${unit}.json" (builtins.toJSON { inherit services; });
    mode = if any (x: x.mode == "external") servicesRaw then "external" else "direct";
  in {
    name = {
      direct = unit;
      external = "register-consul-svc-${unit}";
    }.${mode};
    value = {
      direct = {
        serviceConfig = {
          ExecStartPost = "${consul} services register ${servicesJson}";
          ExecStopPost = "${consul} services deregister ${servicesJson}";
        };
      };
      external = {
        after = [ "${unit}.service" ];
        wantedBy = [ "${unit}.service" ];
        unitConfig.BindsTo = "${unit}.service";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${consul} services register ${servicesJson}";
          ExecStop = "${consul} services deregister ${servicesJson}";
        };
      };
    }.${mode};
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
    systemd.services = mapAttrs' attachToService (groupBy (getAttr "unit") (attrValues cfg.services));
    warnings = optional (!config.services.consul.enable) "Consul service registrations found, but Consul agent is not enabled on this machine.";
  };
}
