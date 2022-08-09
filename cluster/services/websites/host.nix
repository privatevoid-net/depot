{ config, inputs, lib, pkgs, tools, ... }:

let
  importWebsites = expr: import expr {
    tools = tools.nginx;
    packages = inputs.self.packages.${pkgs.system};
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
}
