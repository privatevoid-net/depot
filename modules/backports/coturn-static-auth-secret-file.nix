# based on https://github.com/NixOS/nixpkgs/pull/129059
# FIXME: this module does not verify duplicate settings
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.coturn;
  pidfile = "/run/turnserver/turnserver.pid";
  # unfortunately, we need to re-render the entire config file ourselves
  configFile = pkgs.writeText "turnserver.conf" ''
listening-port=${toString cfg.listening-port}
tls-listening-port=${toString cfg.tls-listening-port}
alt-listening-port=${toString cfg.alt-listening-port}
alt-tls-listening-port=${toString cfg.alt-tls-listening-port}
${concatStringsSep "\n" (map (x: "listening-ip=${x}") cfg.listening-ips)}
${concatStringsSep "\n" (map (x: "relay-ip=${x}") cfg.relay-ips)}
min-port=${toString cfg.min-port}
max-port=${toString cfg.max-port}
${lib.optionalString cfg.lt-cred-mech "lt-cred-mech"}
${lib.optionalString cfg.no-auth "no-auth"}
${lib.optionalString cfg.use-auth-secret "use-auth-secret"}
${lib.optionalString (cfg.static-auth-secret != null) ("static-auth-secret=${cfg.static-auth-secret}")}
realm=${cfg.realm}
${lib.optionalString cfg.no-udp "no-udp"}
${lib.optionalString cfg.no-tcp "no-tcp"}
${lib.optionalString cfg.no-tls "no-tls"}
${lib.optionalString cfg.no-dtls "no-dtls"}
${lib.optionalString cfg.no-udp-relay "no-udp-relay"}
${lib.optionalString cfg.no-tcp-relay "no-tcp-relay"}
${lib.optionalString (cfg.cert != null) "cert=${cfg.cert}"}
${lib.optionalString (cfg.pkey != null) "pkey=${cfg.pkey}"}
${lib.optionalString (cfg.dh-file != null) ("dh-file=${cfg.dh-file}")}
no-stdout-log
syslog
pidfile=${pidfile}
${lib.optionalString cfg.secure-stun "secure-stun"}
${lib.optionalString cfg.no-cli "no-cli"}
cli-ip=${cfg.cli-ip}
cli-port=${toString cfg.cli-port}
${lib.optionalString (cfg.cli-password != null) ("cli-password=${cfg.cli-password}")}
${cfg.extraConfig}
'';
in
{
  options = {
    services.coturn = {
      static-auth-secret-file = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Path to the file containing the static authentication secret.
        '';
      };
    };
  };
  config = mkIf cfg.enable {
    systemd.services.coturn = let
      runConfig = "/run/coturn/turnserver.cfg";
    in {
      preStart = ''
        cat ${configFile} > ${runConfig}
        ${optionalString (cfg.static-auth-secret-file != null) ''
          STATIC_AUTH_SECRET="$(head -n1 ${cfg.static-auth-secret-file} || :)"
          echo "static-auth-secret=$STATIC_AUTH_SECRET" >> ${runConfig}
        '' }
        chmod 640 ${runConfig}
      '';

      serviceConfig = {
        ExecStart = mkForce "${pkgs.coturn}/bin/turnserver -c ${runConfig}";
      };
    };
    systemd.tmpfiles.rules = [
      "d  /run/coturn 0700 turnserver turnserver - -"
    ];
  };
}
