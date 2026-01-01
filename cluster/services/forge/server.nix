{ cluster, config, depot, lib, pkgs, ... }:

let
  inherit (depot.lib.meta) domain;
  inherit (cluster.config.services.forge) secrets;

  patroni = cluster.config.links.patroni-pg-access;

  host = "forge.${domain}";

  protectionLink = cluster.config.hostLinks.${config.networking.hostName}.forge;

  backendLink = config.links.forgejoBackend;

  exe = lib.getExe config.services.forgejo.package;
in

{
  links.forgejoBackend.protocol = "http";

  system.ascensions.forgejo = {
    requiredBy = [ "forgejo.service" ];
    before = [ "forgejo.service" ];
    incantations = i: [
      (i.execShell "chown -R forgejo:forgejo /srv/storage/private/forge")
      (i.execShell "rm -rf /srv/storage/private/forge/data/{attachments,lfs,avatars,repo-avatars,repo-archive,packages,actions_log,actions_artifacts}")
      (i.move "/srv/storage/private/forge" "/srv/planetarium/private/forge")
    ];
  };

  systemd.services.ascend-forgejo.unitConfig = {
    RequiresMountsFor = config.services.forgejo.stateDir;
  };

  services.locksmith.waitForSecrets.forgejo = [
    "garage-forgejo-id"
    "garage-forgejo-secret"
    "patroni-forge"
  ];

  users = {
    users.forgejo.uid = 955;
    groups.forgejo.gid = 949;
  };

  services.forgejo = {
    enable = true;
    package = depot.packages.forgejo;
    stateDir = "${cluster.config.storage.zerofs.fileSystems.planetarium.mountPoint}/private/forge";
    database = {
      createDatabase = false;
      type = "postgres";
      host = patroni.ipv4;
      inherit (patroni) port;
      name = "forge";
      user = "forge";
      passwordFile = "/run/locksmith/patroni-forge";
    };
    settings = {
      DEFAULT = {
        APP_NAME = "The Forge";
      };
      server = {
        DOMAIN = host;
        ROOT_URL = "https://${host}/";
        PROTOCOL = backendLink.protocol;
        HTTP_ADDR = backendLink.ipv4;
        HTTP_PORT = backendLink.port;
        SSH_DOMAIN = "ssh.${host}";
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
      };
      log."logger.xorm.MODE" = "";
      # enabling this will leak secrets to the log
      database.LOG_SQL = false;
    };
    secrets = {
      storage = {
        MINIO_ACCESS_KEY_ID = "/run/locksmith/garage-forgejo-id";
        MINIO_SECRET_ACCESS_KEY = "/run/locksmith/garage-forgejo-secret";
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

  systemd.services.forgejo-protection = let
    policy = pkgs.writeText "go-away-policy.json" (builtins.toJSON {
      challenges = {
        authenticatedCookieCheck = {
          runtime = "http";
          parameters = {
            http-url = "${backendLink.url}/user/stopwatches";
            http-method = "GET";
            http-cookie = "i_like_gitea";
            http-code = 200;
            verify-probability = 0.1;
          };
        };
      };
      conditions = {
        staticAsset = [
          ''path == "/apple-touch-icon.png"''
          ''path == "/apple-touch-icon-precomposed.png"''
          ''path.startsWith("/assets/")''
          ''path.startsWith("/repo-avatars/")''
          ''path.startsWith("/avatars/")''
          ''path.startsWith("/avatar/")''
          ''path.startsWith("/user/avatar/")''
          ''path.startsWith("/attachments/")''
        ];
        gitRemotePath = [
          ''path.matches("^/[^/]+/[^/]+/(git-upload-pack|git-receive-pack|HEAD|info/refs|info/lfs|objects)")''
        ];
        weirdUserAgent = [
          ''userAgent.contains("Presto/") || userAgent.contains("Trident/")''
          ''userAgent.matches("MSIE ([2-9]|10|11)\\.")''
          ''userAgent.matches("Linux i[63]86") || userAgent.matches("FreeBSD i[63]86")''
          ''userAgent.matches("Windows (3|95|98|CE)") || userAgent.matches("Windows NT [1-5]\\.")''
          ''userAgent.matches("Android [1-5]\\.") || userAgent.matches("(iPad|iPhone) OS [1-9]_")''
          ''userAgent.startsWith("Opera/")''
          ''userAgent.matches("^Mozilla/[1-4]")''
        ];
        heavyResource = [
          ''path.startsWith("/explore/")''
          ''path.matches("^/[^/]+/[^/]+/src/commit/")''
          ''path.matches("^/[^/]+/[^/]+/compare/")''
          ''path.matches("^/[^/]+/[^/]+/commits/commit/")''
          ''path.matches("^/[^/]+/[^/]+/blame/")''
          ''path.matches("^/[^/]+/[^/]+/search/")''
          ''path.matches("^/[^/]+/[^/]+/find/")''
          ''path.matches("^/[^/]+/[^/]+/activity")''
          ''path.matches("^/[^/]+/[^/]+/graph$")''
          ''"q" in query && query.q != ""''
          ''path.matches("^/[^/]+$") && "tab" in query && query.tab == "activity"''
        ];
      };
      rules = [
        {
          name = "allowWellKnown";
          conditions = [ "($is-well-known-asset)" ];
          action = "pass";
        }
        {
          name = "allowStatic";
          conditions = [ "($staticAsset)" ];
          action = "pass";
        }
        {
          name = "emptyUserAgent";
          conditions = [ ''userAgent == ""'' ];
          action = "deny";
        }
        {
          name = "weirdUserAgent";
          conditions = [ "($weirdUserAgent)" ];
          action = "none";
          children = [
            {
              name = 0;
              action = "check";
              settings.challenges = [ "js-refresh" "authenticatedCookieCheck" ];
            }
            {
              name = 1;
              action = "check";
              settings.challenges = [ "preload-link" "resource-load" ];
            }
            {
              name = 2;
              action = "check";
              settings.challenges = [ "header-refresh" ];
            }
          ];
        }
        {
          name = "allowGitOperations";
          conditions = [
            "($gitRemotePath)"
            ''path.matches("^/[^/]+/[^/]+\\.git")''
            ''path.matches("^/[^/]+/[^/]+/") && ($is-git-ua)''
          ];
          action = "pass";
        }
        {
          name = "allowApiCalls";
          conditions = [
            ''path.startsWith("/api/v1/") || path.startsWith("/api/forgejo/v1/")''
            ''path.startsWith("/login/oauth/")''
            ''path.startsWith("/captcha/")''
            ''path.startsWith("/metrics/")''
            ''path == "/-/markup"''
            ''path == "/user/events"''
            ''path == "/ssh_info"''
            ''path == "/api/healthz"''
            ''path.startsWith("/api/actions/") || path.startsWith("/api/actions_pipeline/")''
            ''path.matches("^/[^/]+\\.keys$")''
            ''path.matches("^/[^/]+\\.gpg")''
            ''path.startsWith("/api/packages/") || path == "/api/packages"''
            ''path.startsWith("/v2/") || path == "/v2"''
            ''path.endsWith("/branches/list") || path.endsWith("/tags/list")''
          ];
          action = "pass";
        }
        {
          name = "allowPreviewCard";
          conditions = [
            ''path.endsWith("/-/summary-card") || path.matches("^/[^/]+/[^/]+/releases/summary-card/[^/]+$")''
          ];
          action = "pass";
        }
        {
          name = "allowMainPages";
          conditions = [
            ''path == "/"''
            ''(path.matches("^/[^/]+/[^/]+/?$") || path.matches("^/[^/]+/[^/]+/badges/") || path.matches("^/[^/]+/[^/]+/(issues|pulls)/[0-9]+$") || (path.matches("^/[^/]+/?$") && size(query) == 0)) && !path.matches("(?i)^/(api|metrics|v2|assets|attachments|avatar|avatars|repo-avatars|captcha|login|org|repo|user|admin|devtest|explore|issues|pulls|milestones|notifications|ghost)(/|$)")''
          ];
          action = "pass";
        }
        {
          name = "heavyResource";
          conditions = [ "($heavyResource)" ];
          action = "none";
          children = [
            {
              name = 0;
              action = "check";
              settings.challenges = [
                "authenticatedCookieCheck" "preload-link" "header-refresh" "js-refresh"
              ];
            }
            {
              name = 1;
              action = "check";
              settings.challenges = [
                "authenticatedCookieCheck" "resource-load" "js-refresh"
              ];
            }
          ];
        }
        {
          name = "sourceDownload";
          conditions = [
            ''path.matches("^/[^/]+/[^/]+/raw/branch/")''
            ''path.matches("^/[^/]+/[^/]+/archive/")''
            ''path.matches("^/[^/]+/[^/]+/releases/download/")''
            ''path.matches("^/[^/]+/[^/]+/media/") && ($is-generic-browser)''
          ];
          action = "pass";
        }
        {
          name = "browser";
          action = "challenge";
          conditions = [ "($is-generic-browser)" ];
          settings.challenges = [
            "authenticatedCookieCheck" "preload-link" "resource-load" "meta-refresh"
          ];
        }
      ];
    });
  in {
    requiredBy = [ "forgejo.service" ];
    wantedBy = [ "multi-user.target" ];
    before = [ "forgejo.service" ];
    serviceConfig = {
      DynamicUser = true;
      ExecStart = lib.escapeShellArgs [
        "${pkgs.go-away}/bin/go-away"
        "--bind" protectionLink.tuple
        "--backend" "${host}=${backendLink.url}"
        "--client-ip-header" "X-Forwarded-For"
        "--policy-snippets" "${pkgs.go-away}/lib/go-away/snippets"
        "--policy" policy
      ];
    };
  };
}
