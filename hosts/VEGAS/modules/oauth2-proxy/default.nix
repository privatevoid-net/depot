{ config, depot, ... }:
let
  inherit (depot.lib.meta) domain;
  login = x: "https://login.${domain}/auth/realms/master/protocol/openid-connect/${x}";
in
{
  age.secrets.oauth2_proxy-secrets = {
    file = ../../../../secrets/oauth2_proxy-secrets.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  services.oauth2-proxy = {
    enable = true;
    nginx.domain = config.services.keycloak.settings.hostname;
    approvalPrompt = "auto";
    provider = "keycloak";
    scope = "openid";
    clientID = "net.privatevoid.admin-interfaces1";
    keyFile = config.age.secrets.oauth2_proxy-secrets.path;
    loginURL = login "auth";
    redeemURL = login "token";
    validateURL = login "userinfo";
    cookie = {
      secure = true;
      domain = ".${domain}";
    };
    email.domains = [ domain ];
    extraConfig = {
      keycloak-group = "/admins";
      skip-provider-button = true;
    };
  };
}
