{ config, lib, pkgs, ... }:

with lib;

let
  consul = config.services.consul.package;

  consulCfg = config.services.consul.extraConfig;
  consulHttpAddr = "${consulCfg.addresses.http or "127.0.0.1"}:${toString (consulCfg.ports.http or 8500)}";
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

      svcs = map (x: config.consul.services.${x}) cfg.registerServices;

      runWithRegistration = pkgs.writeShellScript "run-with-registration" ''
        trap '${lib.concatStringsSep ";" (map (svc: svc.commands.deregister) svcs)}' EXIT
        ${lib.concatStringsSep "\n" (
          map (svc: svc.commands.register) svcs
        )}
        ''${@}
      '';

      waitForConsul = pkgs.writeShellScript "wait-for-consul" ''
        while ! ${consul}/bin/consul lock --name="pre-flight-check" --n=${toString cfg.replicas} --shell=false "$1-pre-flight-check-${config.networking.hostName}-$RANDOM" ${pkgs.coreutils}/bin/true; do
          sleep 1
        done
      '';

      hasSpecialPrefix = elem (substring 0 1 ExecStart) [ "@" "-" ":" "+" "!" ];
    in assert !hasSpecialPrefix; pkgs.writeTextDir "etc/systemd/system/${n}.service.d/distributed.conf" ''
      [Unit]
      Requires=consul-ready.target
      After=consul-ready.target

      [Service]
      ExecStartPre=${waitForConsul} 'services/${n}%i'
      ExecStart=
      ExecStart=${consul}/bin/consul lock --name=${n} --n=${toString cfg.replicas} --shell=false --child-exit-code 'services/${n}%i' ${optionalString (cfg.registerServices != []) runWithRegistration} ${ExecStart}
      Environment="CONSUL_HTTP_ADDR=${consulHttpAddr}"
      Environment="CONSUL_HTTP_TOKEN_FILE=/run/locksmith/consul-systemManagementToken"
      ${optionalString (v.serviceConfig ? RestrictAddressFamilies) "RestrictAddressFamilies=AF_NETLINK"}
      ${optionalString (cfg.registerServices != []) (lib.concatStringsSep "\n" (map (svc: "ExecStopPost=${svc.commands.deregister}") svcs))}
    ''))
  ];
}
