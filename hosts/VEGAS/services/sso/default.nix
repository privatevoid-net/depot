{ config, lib, pkgs, tools, ... }:
with tools.nginx;
let
  login = "login.${tools.meta.domain}";
  cfg = config.services.keycloak;
  kc = config.links.keycloak;
in
{
  tested.requiredChecks = [ "keycloak" ];
  links.keycloak.protocol = "http";

  imports = [
    ./identity-management.nix
  ];
  age.secrets.keycloak-dbpass = {
    file = ../../../../secrets/keycloak-dbpass.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
  services.nginx.virtualHosts = { 
    "${login}" = lib.recursiveUpdate (vhosts.proxy kc.url) {
      locations."= /".return = "302 /auth/realms/master/account/";
    };
    "account.${domain}" = vhosts.redirect "https://${login}/auth/realms/master/account/";
  };
  services.keycloak = {
    enable = true;
    database = {
      createLocally = true;
      type = "postgresql";
      passwordFile = config.age.secrets.keycloak-dbpass.path;
    };
    settings = {
      http-host = kc.ipv4;
      http-port = kc.port;
      hostname = login;
      proxy = "edge";
      # for backcompat, TODO: remove
      http-relative-path = "/auth";
    };
  };
}
