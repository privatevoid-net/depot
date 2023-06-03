{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.consul;

  consul = "${config.services.consul.package}/bin/consul";

  writeLoopScript = name: cmd: pkgs.writeShellScript name ''
    while ! ${cmd}; do
      sleep 1
    done
  '';

  consulRegisterScript = writeLoopScript "consul-register" ''${consul} services register "$1"'';

  consulDeregisterScript = writeLoopScript "consul-deregister" ''${consul} services deregister "$1"'';

  register = servicesJson: "${consulRegisterScript} ${servicesJson}";

  deregister = servicesJson: "${consulDeregisterScript} ${servicesJson}";

  writeServicesJson = name: services: pkgs.writeText "consul-services-${name}.json" (builtins.toJSON { inherit services; });

  consulServiceDefinition = types.submodule ({ config, name, ... }: {
    options = {
      unit = mkOption {
        description = "Which systemd service to attach to.";
        default = name;
        type = types.str;
      };
      mode = mkOption {
        description = "How to attach command executions to the service.";
        type = types.enum [ "direct" "external" "manual" ];
        default = "direct";
      };
      definition = mkOption {
        description = "Consul service definition.";
        type = types.attrs;
      };
      commands = {
        register = mkOption {
          description = "Command used to register this service.";
          type = types.str;
          readOnly = true;
        };
        deregister = mkOption {
          description = "Command used to deregister this service.";
          type = types.str;
          readOnly = true;
        };
      };
    };
    config.commands = let
      servicesJson = writeServicesJson name [ config.definition ];
    in {
      register = register servicesJson;
      deregister = deregister servicesJson;
    };
  });

  attachToService = unit: servicesRaw: let
    services = map (getAttr "definition") servicesRaw;
    servicesJson = writeServicesJson unit services;
    mode = if any (x: x.mode == "external") servicesRaw then "external" else "direct";
  in {
    name = {
      direct = unit;
      external = "register-consul-svc-${unit}";
    }.${mode};
    value = {
      direct = {
        serviceConfig = {
          ExecStartPost = register servicesJson;
          ExecStopPost = deregister servicesJson;
        };
      };
      external = {
        after = [ "${unit}.service" ];
        wantedBy = [ "${unit}.service" ];
        unitConfig.BindsTo = "${unit}.service";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = register servicesJson;
          ExecStop = deregister servicesJson;
          Restart = "on-failure";
          RestartSec = "30s";
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

  config = lib.mkIf (cfg.services != {}) (let
    servicesRaw = filter (x: x.mode != "manual") (attrValues cfg.services);
  in {
    systemd.services = mapAttrs' attachToService (groupBy (getAttr "unit") servicesRaw);

    warnings = optional (!config.services.consul.enable) "Consul service registrations found, but Consul agent is not enabled on this machine.";
  });
}
