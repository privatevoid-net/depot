{ config, lib, pkgs, ... }:

let
  consul = config.links.consulAgent;

  kvRoot = "secrets/locksmith";
  kvValue = "recipient/${config.networking.hostName}";
in

{
  options.services.locksmith.waitForSecrets = lib.mkOption {
    type = with lib.types; attrsOf (listOf str);
    default = {};
  };

  config = lib.mkMerge [
    {
      systemd.services = lib.mapAttrs' (name: secrets: {
        name = "locksmith-wait-secrets-${name}";
        value = {
          description = "Wait for secrets: ${name}";
          after = [ "locksmith.service" ];
          before = [ "${name}.service" ];
          requiredBy = [ "${name}.service" ];
          serviceConfig = {
            Type = "oneshot";
            IPAddressDeny = [ "any" ];
          };
          path = [
            pkgs.inotify-tools
          ];
          script = ''
            for key in ${lib.escapeShellArgs secrets}; do
              if ! test -e "/run/locksmith/$key"; then
                echo "Waiting for secret: $key"
                inotifywait -qq -e create,moved_to --include "^/run/locksmith/''${key}$" /run/locksmith
              fi
              echo "Heard secret: $key"
            done
            echo "All secrets known."
          '';
        };
      }) config.services.locksmith.waitForSecrets;
    }
    {
      systemd.tmpfiles.settings.locksmith = {
        "/run/locksmith".d = {
          mode = "0711";
        };
      };

      systemd.services.locksmith = {
        description = "The Locksmith's Chant";
        wantedBy = [ "multi-user.target" ];
        wants = [ "consul.service" ];
        after = [ "consul.service" ];
        chant.enable = true;
        path = [
          config.services.consul.package
        ];
        environment = {
          CONSUL_HTTP_ADDR = consul.tuple;
        };
        serviceConfig = {
          PrivateTmp = true;
          WorkingDirectory = "/tmp";
          IPAddressDeny = [ "any" ];
          IPAddressAllow = [ consul.ipv4 ];
          LoadCredential = lib.mkForce [];
        };
        script = ''
          consul kv get --keys ${kvRoot}/ | ${pkgs.gnused}/bin/sed 's,/$,,g' | while read secret; do
            out="$(mktemp -u /run/locksmith/.locksmith-secret.XXXXXXXXXXXXXXXX)"
            if [[ "$(consul kv get --keys "$secret/${kvValue}")" == "$secret/${kvValue}" ]]; then
              owner="$(consul kv get "$secret/owner")"
              group="$(consul kv get "$secret/group")"
              mode="$(consul kv get "$secret/mode")"
              consul kv get "$secret/${kvValue}" | ${pkgs.age}/bin/age --decrypt -i /etc/ssh/ssh_host_ed25519_key -o $out
              chown -v "$owner:$group" $out
              chmod -v "$mode" $out
              mv -v $out "/run/locksmith/$(basename "$secret")"
            fi
          done
        '';
      };
    }
  ];
}
