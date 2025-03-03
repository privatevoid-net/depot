{ config, depot, lib, ... }:

let
  importWebsites = expr: import expr {
    tools = depot.lib.nginx;
    inherit (depot) packages;
  };

  acmeUseDNS = name: conf: {
    name = conf.useACMEHost or conf.serverName or name;
    value = {
      dnsProvider = "exec";
      webroot = null;
    };
  };

  isACME = _: conf: conf ? enableACME && conf.enableACME;

  websites = depot.lib.nginx.mappers.mapSubdomains (importWebsites ./websites.nix);
in {
  security.acme.certs = lib.mkIf config.services.nginx.enable (lib.mapAttrs' acmeUseDNS (lib.filterAttrs isACME websites));
  services.nginx.virtualHosts = websites;
}
