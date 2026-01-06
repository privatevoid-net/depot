{ config, depot, lib, pkgs, ... }:

let
  kvRoot = "secrets/locksmith";
  activeProvders = lib.filterAttrs (_: cfg: lib.any (secret: secret.nodes != []) (lib.attrValues cfg.secrets)) config.services.locksmith.providers;
  refreshProviders = lib.filterAttrs (_: cfg: lib.pipe cfg.secrets [
    lib.attrValues
    (map (x: x.updateInterval))
    (lib.filter lib.isInt)
    (xs: xs != [])
  ]) activeProvders;
in

{
  options.services.locksmith = with lib; {
    providers = mkOption {
      type = types.attrsOf (types.submodule ({ ... }: {
        options = {
          wantedBy = mkOption {
            type = types.listOf types.str;
            default = [];
          };
          before = mkOption {
            type = types.listOf types.str;
            default = [];
          };
          after = mkOption {
            type = types.listOf types.str;
            default = [];
          };
          secrets = mkOption {
            type = types.attrsOf (types.submodule ({ ... }: {
              options = {
                nodes = mkOption {
                  type = types.listOf types.str;
                  default = [];
                };
                command = mkOption {
                  type = types.coercedTo types.package (package: "${package}") types.str;
                };
                checkUpdate = mkOption {
                  type = types.coercedTo types.package (package: "${package}") types.str;
                  default = "true";
                };
                updateInterval = mkOption {
                  type = types.nullOr types.ints.unsigned;
                  default = null;
                };
                owner = mkOption {
                  type = types.str;
                  default = "root";
                };
                group = mkOption {
                  type = types.str;
                  default = "root";
                };
                mode = mkOption {
                  type = types.str;
                  default = "0400";
                };
              };
            }));
            default = {};
          };
        };
      }));
      default = {};
    };
  };

  config.systemd.services = lib.mapAttrs' (providerName: providerConfig: {
    name = "locksmith-provider-${providerName}";
    value = let
      providerRoot = "${kvRoot}/${providerName}";
    in {
      description = "Locksmith Provider | ${providerName}";
      distributed.enable = true;
      inherit (providerConfig) wantedBy before after;
      serviceConfig = {
        Type = "oneshot";
        PrivateTmp = true;
        LoadCredential = lib.mkForce [];
      };
      path = [
        config.services.consul.package
        pkgs.age
      ];
      script = let
        activeSecrets = lib.filterAttrs (_: secret: secret.nodes != []) providerConfig.secrets;
        activeNodes = lib.unique (lib.flatten (lib.mapAttrsToList (_: secret: secret.nodes) activeSecrets));
        secretNames = map (name: "${providerRoot}-${name}/") (lib.attrNames activeSecrets);

        createSecret = { path, nodes, owner, mode, group, command, checkUpdate }: ''
          checkUpdateForce() {
            ${lib.concatStringsSep "\n" (map (node: ''
              if ! consul kv get ${lib.escapeShellArg path}/recipient/${node} >/dev/null; then
                return 0
              fi
            '') nodes)}
            return 1
          }
          if checkUpdateForce || (${checkUpdate}); then
            consul kv put ${lib.escapeShellArg path}/mode ${lib.escapeShellArg mode}
            consul kv put ${lib.escapeShellArg path}/owner ${lib.escapeShellArg owner}
            consul kv put ${lib.escapeShellArg path}/group ${lib.escapeShellArg group}
            secret="$(mktemp -ut)"
            (${command}) > "$secret"
            ${lib.concatStringsSep "\n" (map (node: ''
              consul kv put ${lib.escapeShellArg path}/recipient/${node} "$(age < "$secret" --encrypt --armor -r ${lib.escapeShellArg depot.hours.${node}.ssh.id.publicKey})"
            '') nodes)}
          else
            echo Skipping update for ${lib.escapeShellArg path}
          fi
        '';
      in ''
        # create/update secrets
        umask 77
        ${lib.pipe activeSecrets [
          (lib.mapAttrsToList (secretName: secretConfig: createSecret {
            path = "${providerRoot}-${secretName}";
            inherit (secretConfig) nodes mode owner group command checkUpdate;
          }))
          (lib.concatStringsSep "\n")
        ]}

        # delete leftover secrets of this provider
        consul kv get --keys '${providerRoot}-' | grep -v ${lib.concatStringsSep " \\\n  " (map (secret: "-e ${lib.escapeShellArg secret}") secretNames)} | xargs --no-run-if-empty -n1 consul kv delete --recurse

        # notify
        ${lib.pipe activeNodes [
          (map (node: "consul event --name=chant:locksmith --node=${node}"))
          (lib.concatStringsSep "\n")
        ]}
      '';
    };
  }) activeProvders;

  config.systemd.timers = lib.mapAttrs' (providerName: providerConfig: {
    name = "locksmith-refresh-${providerName}";
    value = {
      description = "Locksmith Refresh | ${providerName}";
      timerConfig = {
        Unit = "locksmith-provider-${providerName}.service";
        OnUnitActiveSec = lib.pipe providerConfig.secrets [
          lib.attrValues
          (map (x: x.updateInterval))
          (lib.filter lib.isInt)
          (lib.foldl' lib.min (365 * 86400))
        ];
      };
    };
  }) refreshProviders;
}
