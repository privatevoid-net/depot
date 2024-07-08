{ cluster, config, depot, lib, pkgs, ... }:

let
  inherit (depot.lib.meta) domain;
  inherit (cluster.config.services.forge) secrets;

  patroni = cluster.config.links.patroni-pg-access;

  host = "forge.${domain}";

  link = cluster.config.hostLinks.${config.networking.hostName}.forge;

  exe = lib.getExe config.services.forgejo.package;
in

{
  system.ascensions.forgejo = {
    requiredBy = [ "forgejo.service" ];
    before = [ "forgejo.service" ];
    incantations = i: [
      (i.execShell "chown -R forgejo:forgejo /srv/storage/private/forge")
      (i.execShell "rm -rf /srv/storage/private/forge/data/{attachments,lfs,avatars,repo-avatars,repo-archive,packages,actions_log,actions_artifacts}")
    ];
  };

  services.forgejo = {
    enable = true;
    package = depot.packages.forgejo;
    stateDir = "/srv/storage/private/forge";
    database = {
      createDatabase = false;
      type = "postgres";
      host = patroni.ipv4;
      inherit (patroni) port;
      name = "forge";
      user = "forge";
      passwordFile = secrets.dbCredentials.path;
    };
    settings = {
      DEFAULT = {
        APP_NAME = "The Forge";
      };
      server = {
        DOMAIN = host;
        ROOT_URL = "https://${host}/";
        PROTOCOL = link.protocol;
        HTTP_ADDR = link.ipv4;
        HTTP_PORT = link.port;
      };
      oauth2_client = {
        REGISTER_EMAIL_CONFIRM = false;
        ENABLE_AUTO_REGISTRATION = true;
        ACCOUNT_LINKING = "auto";
        UPDATE_AVATAR = true;
      };
      session.COOKIE_SECURE = true;
      service = {
        DISABLE_REGISTRATION = false;
        ALLOW_ONLY_INTERNAL_REGISTRATION = false;
        ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
      };
      storage = {
        STORAGE_TYPE = "minio";
        MINIO_ENDPOINT = cluster.config.links.garageS3.hostname;
        MINIO_BUCKET = "forgejo";
        MINIO_USE_SSL = true;
        MINIO_BUCKET_LOOKUP = "path";
        SERVE_DIRECT = true;
      };
      log.ENABLE_XORM_LOG = false;
      # enabling this will leak secrets to the log
      database.LOG_SQL = false;
    };
    secrets = {
      storage = {
        MINIO_ACCESS_KEY_ID = secrets.s3AccessKeyID.path;
        MINIO_SECRET_ACCESS_KEY = secrets.s3SecretAccessKey.path;
      };
    };
  };

  systemd.services.forgejo.preStart = let
    providerName = "PrivateVoidAccount";
    args = lib.escapeShellArgs [
      "--name" providerName
      "--provider" "openidConnect"
      "--key" "net.privatevoid.forge1"
      "--auto-discover-url" "https://login.${domain}/auth/realms/master/.well-known/openid-configuration"
      "--group-claim-name" "groups"
      "--admin-group" "/forge_admins@${domain}"
    ];
  in lib.mkAfter /*bash*/ ''
    providerId="$(${exe} admin auth list | ${pkgs.gnugrep}/bin/grep -w '${providerName}' | cut -f1)"
    if [[ -z "$providerId" ]]; then
      FORGEJO_ADMIN_OAUTH2_SECRET="$(< ${secrets.oidcSecret.path})" ${exe} admin auth add-oauth ${args}
    else
      FORGEJO_ADMIN_OAUTH2_SECRET="$(< ${secrets.oidcSecret.path})" ${exe} admin auth update-oauth --id "$providerId" ${args}
    fi
  '';
}
