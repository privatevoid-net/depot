{ config, depot, lib, pkgs, tools, ... }:

let
  importWebsites = expr: import expr {
    tools = tools.nginx;
    inherit (depot) packages;
  };

  websites = tools.nginx.mappers.mapSubdomains (importWebsites ./websites.nix);

  acmeUseDNS = name: conf: {
    name = conf.useACMEHost or conf.serverName or name;
    value = {
      dnsProvider = "pdns";
      webroot = null;
    };
  };

  isACME = _: conf: conf ? enableACME && conf.enableACME;
in {
  services.nginx.virtualHosts = websites;
  security.acme.certs = lib.mapAttrs' acmeUseDNS (lib.filterAttrs isACME websites);

  consul.services.nginx = {
    mode = "external";
    definition = {
      name = "static-lb";
      address = lib.toLower "${config.networking.hostName}.${config.networking.domain}";
      port = 443;
      checks = lib.singleton {
        interval = "60s";
        tcp = "127.0.0.1:80";
      };
    };
  };
}
