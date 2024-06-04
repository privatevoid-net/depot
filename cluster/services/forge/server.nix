{ cluster, config, depot, lib, pkgs, ... }:

let
  inherit (depot.lib.meta) domain;
  inherit (depot.lib.nginx) vhosts;
  inherit (config.age) secrets;

  patroni = cluster.config.links.patroni-pg-access;

  host = "forge.${domain}";

  link = config.links.forge;

  exe = lib.getExe config.services.forgejo.package;
in

{
  system.ascensions.forgejo = {
    requiredBy = [ "gitea.service" ];
    incantations = i: [ ];
  };

  age.secrets = {
    forgejoOidcSecret = {
      file = ./credentials/forgejo-oidc-secret.age;
      owner = "forgejo";
    };
    forgejoDbCredentials = {
      file = ./credentials/forgejo-db-credentials.age;
      owner = "forgejo";
    };
  };

  links.forge.protocol = "http";

  services.forgejo = {
    enable = true;
    package = depot.packages.forgejo;
    appName = "The Forge";
    stateDir = "/srv/storage/private/forge";
    database = {
      createDatabase = false;
      type = "postgres";
      host = patroni.ipv4;
      inherit (patroni) port;
      name = "forge";
      user = "forge";
      passwordFile = secrets.forgejoDbCredentials.path;
    };
    settings = {
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
      log.ENABLE_XORM_LOG = false;
      # enabling this will leak secrets to the log
      database.LOG_SQL = false;
    };
  };

  services.nginx.virtualHosts."${host}" = vhosts.proxy link.url;

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
      FORGEJO_ADMIN_OAUTH2_SECRET="$(< ${secrets.forgejoOidcSecret.path})" ${exe} admin auth add-oauth ${args}
    else
      FORGEJO_ADMIN_OAUTH2_SECRET="$(< ${secrets.forgejoOidcSecret.path})" ${exe} admin auth update-oauth --id "$providerId" ${args}
    fi
  '';
}
