{ config, lib, pkgs, tools, ... }:
let
  inherit (tools.meta) domain;
  login = x: "https://login.${domain}/auth/realms/master/protocol/openid-connect/${x}";
  cfg = config.services.oauth2_proxy;
in
{
  age.secrets.oauth2_proxy-secrets = {
    file = ../../../../secrets/oauth2_proxy-secrets.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
  services.oauth2_proxy = {
    enable = true;
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
  services.nginx.virtualHosts = lib.genAttrs cfg.nginx.virtualHosts (vhost: {
    # apply protection to the whole vhost, not just /
    extraConfig = ''
      auth_request /oauth2/auth;
      error_page 401 = /oauth2/sign_in;

      # pass information via X-User and X-Email headers to backend,
      # requires running with --set-xauthrequest flag
      auth_request_set $user   $upstream_http_x_auth_request_user;
      auth_request_set $email  $upstream_http_x_auth_request_email;
      proxy_set_header X-User  $user;
      proxy_set_header X-Email $email;

      # if you enabled --cookie-refresh, this is needed for it to work with auth_request
      auth_request_set $auth_cookie $upstream_http_set_cookie;
      add_header Set-Cookie $auth_cookie;
    '';
    locations."/oauth2/".extraConfig = "auth_request off;";
    locations."/oauth2/auth".extraConfig = "auth_request off;";
  });
}
