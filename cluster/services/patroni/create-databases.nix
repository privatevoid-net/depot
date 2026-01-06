{ cluster, config, lib, pkgs, ... }:

let
  inherit (cluster.config.services.patroni) secrets;

  patroni = cluster.config.links.patroni-pg-access;

  cfg = cluster.config.patroni;

  writeQueryFile = pkgs.writeText "patroni-query.sql";

  psqlRunFile = file: ''
    export PGPASSWORD="$(< ${secrets.PATRONI_SUPERUSER_PASSWORD.path})"
    while ! ${config.services.patroni.postgresqlPackage}/bin/psql 'host=${patroni.ipv4} port=${patroni.portStr} dbname=postgres user=postgres' --tuples-only --csv --file="${file}" >&2; do
      sleep 3
    done
  '';

  psql = query: psqlRunFile (writeQueryFile query);

  psqlSecret = getSecret: queryTemplate: let
    queryTemplateFile = writeQueryFile queryTemplate;
  in ''
    umask 77
    secretFile="$(mktemp -ut patroniSecret.XXXXXXXXXXXXXXXX)"
    queryFile="$(mktemp -ut patroniQuery.XXXXXXXXXXXXXXXX)"
    trap "rm -f $secretFile $queryFile" EXIT
    ${getSecret} > "$secretFile"
    cp --no-preserve=mode ${queryTemplateFile} "$queryFile"
    ${pkgs.replace-secret}/bin/replace-secret '@SECRET@' "$secretFile" "$queryFile"
    ${psqlRunFile "$queryFile"}
  '';

  genPassword = pkgs.writeShellScript "patroni-generate-user-password" ''
    base64 -w0 /dev/urandom | tr -d /+ | head -c256
  '';
in

{
  services.incandescence.providers.patroni = lib.mkIf config.services.haproxy.enable {
    locksmith = true;
    wantedBy = [ "patroni.service" "multi-user.target" ];
    partOf = [ "patroni.service" ];
    wants = [ "postgresql.service" ];
    after = [ "postgresql.service" ];

    formulae = {
      user = {
        destroyAfterDays = 0;
        create = user: psql ''
          SELECT 'CREATE USER ${user}'
          WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${user}')\gexec
        '';
        destroy = psqlSecret "printenv OBJECT" ''
          DROP USER @SECRET@;
        '';
      };
      database = {
        destroyAfterDays = 30;
        deps = [ "user" ];
        create = db: psql ''
          SELECT 'CREATE DATABASE ${db} OWNER ${cfg.databases.${db}.owner}'
          WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${db}')\gexec
        '';
        change = db: psql ''
          ALTER DATABASE ${db} OWNER TO ${cfg.databases.${db}.owner};
        '';
        destroy = psqlSecret "printenv OBJECT" ''
          DROP DATABASE @SECRET@;
        '';
      };
    };
  };

  services.locksmith.providers.patroni = lib.mkIf config.services.haproxy.enable {
    secrets = lib.mapAttrs (user: userConfig: {
      command = {
        envFile = ''
          ${psqlSecret genPassword ''
            ALTER USER ${user} PASSWORD '@SECRET@';
          ''}
          echo "PGPASSWORD=$(cat "$secretFile")"
        '';
        pgpass = ''
          ${psqlSecret genPassword ''
            ALTER USER ${user} PASSWORD '@SECRET@';
          ''}
          echo "*:*:*:${user}:$(cat "$secretFile")"
        '';
        raw = ''
          ${psqlSecret genPassword ''
            ALTER USER ${user} PASSWORD '@SECRET@';
          ''}
          cat "$secretFile"
        '';
      }.${userConfig.locksmith.format};
      checkUpdate = "false";
      inherit (userConfig.locksmith) nodes owner group mode;
    }) cfg.users;
  };
}
