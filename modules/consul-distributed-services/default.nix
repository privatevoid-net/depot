{ config, lib, pkgs, ... }:

with lib;

let
  consul = config.services.consul.package;
in
{
  options.systemd.services = mkOption {
    type = with types; attrsOf (submodule ({ config, ... }: let
      cfg = config.distributed;
    in {
      config = mkIf cfg.enable {

      };
    }));
  };

  config.systemd.packages = pipe config.systemd.services [
    (filterAttrs (_: v: v.distributed.enable))
    (mapAttrsToList (n: v: let
      inherit (v.serviceConfig) ExecStart;

      cfg = v.distributed;

      svc = config.consul.services.${cfg.registerService};

      runWithRegistration = pkgs.writeShellScript "run-with-registration" ''
        trap '${svc.commands.deregister}' EXIT
        ${svc.commands.register}
        ''${@}
      '';

      hasSpecialPrefix = elem (substring 0 1 ExecStart) [ "@" "-" ":" "+" "!" ];
    in assert !hasSpecialPrefix; pkgs.writeTextDir "etc/systemd/system/${n}.service.d/distributed.conf" ''
      [Service]
      ExecStart=
      ExecStart=${consul}/bin/consul lock --name=${n} --n=${toString cfg.replicas} --shell=false --child-exit-code 'services/${n}%i' ${optionalString (cfg.registerService != null) runWithRegistration} ${ExecStart}
      ${optionalString (v.serviceConfig ? RestrictAddressFamilies) "RestrictAddressFamilies=AF_NETLINK"}
      ${optionalString (cfg.registerService != null) "ExecStopPost=${svc.commands.deregister}"}
    ''))
  ];
}
