{ cluster, config, lib, ... }:

let
  inherit (lib) concatStringsSep escapeShellArg flatten filter filterAttrs length mapAttrs mapAttrs' mapAttrsToList mkIf mkMerge pipe stringToCharacters;

  cfg = config.services.incandescence;
  clusterCfg = cluster.config.incandescence;
in

{
  systemd.services = pipe cfg.providers [
    (mapAttrsToList (provider: providerConfig: pipe providerConfig.formulae [
      (mapAttrsToList (formula: formulaConfig: let
        kvRoot = "services/incandescence/providers/${provider}/formulae/${formula}";
        time = "$(date +%s)";
      in {
        "ignite-${provider}-${formula}-create" = {
          description = "Ignite Creation: ${provider} - ${formula}";
          wantedBy = [ "incandescence-${provider}.target" ];
          before = [ "incandescence-${provider}.target" ];
          wants = providerConfig.wants ++ map (dep: "ignite-${provider}-${dep}-create.service") formulaConfig.deps;
          after = providerConfig.after ++ map (dep: "ignite-${provider}-${dep}-create.service") formulaConfig.deps;
          serviceConfig.Type = "oneshot";
          distributed.enable = true;
          path = [ config.services.consul.package ] ++ providerConfig.packages;
          script = pipe clusterCfg.providers.${provider}.objects.${formula} [
            (map (object: ''
              if ! consul kv get ${kvRoot}/${object}/alive >/dev/null; then
                echo "Create ${formula}: ${object}"
                if (
                ${formulaConfig.create object}
                )
                then
                  consul kv put ${kvRoot}/${object}/alive true
                  consul kv delete ${kvRoot}/${object}/destroyOn
                else
                  echo "Creation failed: ${object}"
                fi
              fi
            ''))
            (concatStringsSep "\n")
          ];
        };
        "ignite-${provider}-${formula}-change" = mkIf (formulaConfig.change != null) {
          description = "Ignite Change: ${provider} - ${formula}";
          wantedBy = [ "incandescence-${provider}.target" ];
          before = [ "incandescence-${provider}.target" ];
          wants = providerConfig.wants ++ [ "ignite-${provider}-${formula}-create.service" ] ++ map (dep: "ignite-${provider}-${dep}-change.service") formulaConfig.deps;
          after = providerConfig.after ++ [ "ignite-${provider}-${formula}-create.service" ] ++ map (dep: "ignite-${provider}-${dep}-change.service") formulaConfig.deps;
          serviceConfig.Type = "oneshot";
          distributed.enable = true;
          path = [ config.services.consul.package ] ++ providerConfig.packages;
          script = pipe clusterCfg.providers.${provider}.objects.${formula} [
            (map (object: ''
              echo "Change ${formula}: ${object}"
              (
              ${formulaConfig.change object}
              ) || echo "Change failed: ${object}"
            ''))
            (concatStringsSep "\n")
          ];
        };
        "ignite-${provider}-${formula}-destroy" = {
          description = "Ignite Destruction: ${provider} - ${formula}";
          wantedBy = [ "incandescence-${provider}.target" ] ++ map (dep: "ignite-${provider}-${dep}-destroy.service") formulaConfig.deps;
          before = [ "incandescence-${provider}.target" ] ++ map (dep: "ignite-${provider}-${dep}-destroy.service") formulaConfig.deps;
          wants = providerConfig.wants ++ [ "ignite-${provider}-${formula}-change.service" ];
          after = providerConfig.after ++ [ "ignite-${provider}-${formula}-change.service" ];
          serviceConfig.Type = "oneshot";
          distributed.enable = true;
          path = [ config.services.consul.package ] ++ providerConfig.packages;
          script = let
            fieldNum = pipe kvRoot [
              stringToCharacters
              (filter (x: x == "/"))
              length
              (builtins.add 2)
              toString
            ];
            keyFilter = pipe clusterCfg.providers.${provider}.objects.${formula} [
              (map (x: escapeShellArg "^${x}$"))
              (concatStringsSep " \\\n  -e ")
            ];
            destroyAfterDays = toString formulaConfig.destroyAfterDays;
          in ''
            consul kv get --keys ${kvRoot}/ | cut -d/ -f${fieldNum} | grep -v -e ${keyFilter} | while read object; do
              if consul kv get ${kvRoot}/$object/alive >/dev/null; then
                destroyOn="$(consul kv get ${kvRoot}/$object/destroyOn || true)"
                if [[ -z "$destroyOn" && "${destroyAfterDays}" -ne 0 ]]; then
                  echo "Schedule ${formula} for destruction in ${destroyAfterDays} days: $object"
                  consul kv put ${kvRoot}/$object/destroyOn "$((${time} + 86400 * ${destroyAfterDays}))"
                elif [[ "${destroyAfterDays}" -eq 0 || "${time}" -ge "$destroyOn" ]]; then
                  echo "Destroy ${formula}: $object"
                  export OBJECT="$object"
                  if (
                  ${formulaConfig.destroy}
                  )
                  then
                    consul kv delete --recurse ${kvRoot}/$object
                  else
                    echo "Destruction failed: $object"
                  fi
                else
                  echo "Scheduled for destruction on $destroyOn (now: ${time})"
                fi
              fi
            done
          '';
        };
      }))
    ]))
    flatten
    mkMerge
  ];

  systemd.targets = mapAttrs' (provider: providerConfig: {
    name = "incandescence-${provider}";
    value = {
      description = "An Incandescence | ${provider}";
      inherit (providerConfig) wantedBy partOf;
    };
  }) cfg.providers;

  services.locksmith.providers = mapAttrs (provider: providerConfig: {
    wantedBy = [ "incandescence-${provider}.target" ];
    after = [ "incandescence-${provider}.target" ];
  }) (filterAttrs (_: providerConfig: providerConfig.locksmith) cfg.providers);
}
