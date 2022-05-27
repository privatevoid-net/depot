{ config, lib, pkgs, tools, ... }:
with tools.nginx;
let
  login = "login.${tools.meta.domain}";
  cfg = config.services.keycloak;
in
{
  reservePortsFor = [ "keycloak" ];

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
    "${login}" = lib.recursiveUpdate (vhosts.proxy "http://${cfg.bindAddress}:${config.portsStr.keycloak}") {
      locations."= /".return = "302 /auth/realms/master/account/";
    };
    "account.${domain}" = vhosts.redirect "https://${login}/auth/realms/master/account/";
  };
  services.keycloak = {
    enable = true;
    frontendUrl = "https://${login}/auth";
    bindAddress = "127.0.0.1";
    httpPort = config.portsStr.keycloak;
    database = {
      createLocally = true;
      type = "postgresql";
      passwordFile = config.age.secrets.keycloak-dbpass.path;
    };
    extraConfig = {
      "subsystem=undertow" = {
        "server=default-server" = {
          "http-listener=default" = {
            proxy-address-forwarding = true;
          };
        };
      };
    };
  };
}
