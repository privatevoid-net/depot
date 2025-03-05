{ cluster, config, lib, pkgs, ... }:

{
  services.locksmith.providers.attic = {
    wantedBy = [ "atticd.service" "multi-user.target" ];
    after = [ "atticd.service" ];
    secrets = lib.mapAttrs (name: token: {
      command = let
        tokenPermissions = {
          inherit (token) push pull delete;
          create-cache = token.createCache;
          configure-cache = token.configureCache;
          configure-cache-retention = token.configureCacheRetention;
          destroy-cache = token.destroyCache;
        };

        mkPermissionFlags = flag: permissions: map (pattern: [ "--${flag}" pattern ]) permissions;

        makeToken = lib.pipe [
            "${config.systemd.package}/bin/systemd-run"
            "--quiet"
            "--pipe"
            "--wait"
            "--collect"
            "--service-type=exec"
            "--property=EnvironmentFile=${config.services.atticd.environmentFile}"
            "--property=DynamicUser=yes"
            "--property=User=${config.services.atticd.user}"
            "--working-directory" "/"
            "${config.services.atticd.package}/bin/atticadm"
            "-f" ((pkgs.formats.toml {}).generate "server.toml" config.services.atticd.settings)
            "make-token"
            "--sub" token.subject
            "--validity" "${toString token.validityDays} days"
            (lib.mapAttrsToList mkPermissionFlags tokenPermissions)
        ] [
            lib.flatten
            lib.escapeShellArgs
        ];
      in ''
        newAtticToken="$(${makeToken})"
        if [[ $? -eq 0 ]]; then
          consul kv put secrets/locksmith/attic-${name}/extra/expires "$(($(date +%s) + ${toString (86400 * token.validityDays)}))" >&2
          echo "$newAtticToken"
        else
          exit 1
        fi
      '';
      checkUpdate = ''
        expirationDate="$(consul kv get secrets/locksmith/attic-${name}/extra/expires)"
        [[ $? -ne 0 ]] && exit 0
        [[ "$expirationDate" -lt "$(($(date +%s) + ${toString (86400 * 5)}))" ]]
      '';
      updateInterval = 86400 * 3;
      inherit (token.locksmith) nodes;
    }) cluster.config.attic.tokens;
  };
}
