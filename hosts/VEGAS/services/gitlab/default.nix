{ config, lib, tools, ... }:

let
  inherit (tools.meta) domain adminEmail;

  mkSecret = name: {
    owner = "gitlab";
    group = "gitlab";
    mode = "0400";
    file = ../../../../secrets/${name}.age;
  };

  secrets = lib.mapAttrs (_: v: v.path) config.age.secrets;

  cfg = config.services.gitlab;
in

{
  age.secrets = lib.flip lib.genAttrs mkSecret [
    "gitlab-initial-root-password"
    "gitlab-openid-secret"
    "gitlab-runner-registration"
    "gitlab-secret-db"
    "gitlab-secret-jws"
    "gitlab-secret-otp"
    "gitlab-secret-secret"
  ];

  services.gitlab = {
    enable = true;
    https = true;
    host = "git.${domain}";
    port = 443;

    initialRootEmail = adminEmail;

    statePath = "/srv/storage/private/gitlab/state";

    smtp = {
      enable = true;
      inherit domain;
    };

    initialRootPasswordFile = secrets.gitlab-initial-root-password;

    secrets = with secrets; {
      dbFile = gitlab-secret-db;
      jwsFile = gitlab-secret-jws;
      otpFile = gitlab-secret-otp;
      secretFile = gitlab-secret-secret;
    };

    extraConfig = {
      omniauth = {
        enabled = true;
        auto_sign_in_with_provider = "openid_connect";
        allow_single_sign_on = ["openid_connect"];
        block_auto_created_users = false;
        providers = [

          {
            name = "openid_connect";
            label = "Private Void Account";
            args = {
              name = "openid_connect";
              scope = ["openid" "profile"];
              response_type = "code";
              issuer = "https://login.${domain}/auth/realms/master";
              discovery = true;
              client_auth_method = "query";
              uid_field = "preferred_username";
              client_options = {
                identifier = "net.privatevoid.git2";
                secret = { _secret = secrets.gitlab-openid-secret; };
                redirect_uri = "https://${cfg.host}/users/auth/openid_connect/callback";
              };
            };
          }
          
        ];
      };
    };
  };

  services.gitlab-runner = {
    enable = true;
    services = {
      shell = {
        # File should contain at least these two variables:
        # `CI_SERVER_URL`
        # `REGISTRATION_TOKEN`
        registrationConfigFile = secrets.gitlab-runner-registration;
        executor = "shell";
        tagList = [ "shell" ];
      };
    };
  };

  services.nginx.virtualHosts."${cfg.host}" = tools.nginx.vhosts.proxy "http://unix:/run/gitlab/gitlab-workhorse.socket";
}
