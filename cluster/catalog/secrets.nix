{ config, lib, withSystem, ... }:

let
  inherit (config) cluster hours;
in

{
  perSystem = { config, pkgs, system, ... }: {
    catalog.cluster = {
      secrets = lib.pipe cluster.config.services [
        (lib.mapAttrsToList (svcName: svcConfig: lib.mapAttrsToList (secretName: secretConfig: {
          name = "${svcName}/${secretName}";
          value = {
            description = "Cluster secret '${secretName}' of service '${svcName}'";
            actions = let
              agenixRules = builtins.toFile "agenix-rules-shim.nix" /*nix*/ ''
                builtins.fromJSON (builtins.readFile (builtins.getEnv "AGENIX_KEYS_JSON"))
              '';

              mkKeys = secretFile: nodes: builtins.toFile "agenix-keys.json" (builtins.toJSON {
                "${secretFile}".publicKeys = (map (hour: hours.${hour}.ssh.id.publicKey) nodes) ++ cluster.config.secrets.extraKeys;
              });

              setupCommands = secretFile: nodes: let
                agenixKeysJson = mkKeys secretFile nodes;
              in ''
                export RULES='${agenixRules}'
                export AGENIX_KEYS_JSON='${agenixKeysJson}'
                mkdir -p "$PRJ_ROOT/cluster/secrets"
                cd "$PRJ_ROOT/cluster/secrets"
              '';
            in (lib.optionalAttrs (secretConfig.generate != null) {
              generateSecret = {
                description = "Generate this secret";
                command = if secretConfig.shared then let
                  secretFile = "${svcName}-${secretName}.age";
                in ''
                  ${setupCommands secretFile secretConfig.nodes}
                  ${withSystem system secretConfig.generate} | agenix -e '${secretFile}'
                '' else lib.concatStringsSep "\n" (map (node: let
                  secretFile = "${svcName}-${secretName}-${node}.age";
                in ''
                  ${setupCommands secretFile [ node ]}
                  ${withSystem system secretConfig.generate} | agenix -e '${secretFile}'
                '') secretConfig.nodes);
              };
            }) // (if secretConfig.shared then let
              secretFile = "${svcName}-${secretName}.age";
            in {
              editSecret = {
                description = "Edit this secret";
                command = ''
                  ${setupCommands secretFile secretConfig.nodes}
                  agenix -e '${secretFile}'
                '';
              };
            } else lib.mapAttrs' (name: lib.nameValuePair "editSecretInstance-${name}") (lib.genAttrs secretConfig.nodes (node: let
              secretFile = "${svcName}-${secretName}-${node}.age";
            in {
              description = "Edit this secret for '${node}'";
              command = ''
                ${setupCommands secretFile [ node ]}
                agenix -e '${secretFile}'
              '';
            })));
          };
        }) svcConfig.secrets))
        lib.concatLists
        lib.listToAttrs
      ];
    };
  };
}
