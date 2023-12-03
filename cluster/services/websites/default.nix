{ depot, lib, ... }:

let
  inherit (depot.lib.meta) domain;

  acmeUseDNS = name: conf: {
    name = conf.useACMEHost or conf.serverName or name;
    value = {
      dnsProvider = "pdns";
      webroot = null;
    };
  };

  isACME = _: conf: conf ? enableACME && conf.enableACME;
in

{
  services.websites = {
    nodes.host = [ "checkmate" "thunderskin" "VEGAS" "prophet" ];
    nixos.host = { config, depot, ... }: let

      importWebsites = expr: import expr {
        tools = depot.lib.nginx;
        inherit (depot) packages;
      };

      websites = depot.lib.nginx.mappers.mapSubdomains (importWebsites ./websites.nix);

    in {
      services.nginx.virtualHosts = websites;
      security.acme.certs = lib.mapAttrs' acmeUseDNS (lib.filterAttrs isACME websites);
      consul.services.nginx = {
        mode = "external";
        definition = {
          name = "static-lb";
          address = depot.reflection.interfaces.primary.addrPublic;
          port = 443;
          checks = lib.singleton {
            interval = "60s";
            tcp = "127.0.0.1:80";
          };
        };
      };
    };
  };

  monitoring.blackbox.targets = {
    web = {
      address = "https://www.${domain}";
      module = "https2xx";
    };
  };

  dns.records = lib.mkMerge [
    (lib.genAttrs [ "www" "draw" "stop-using-nix-env" "whoami" ] (lib.const {
      consulService = "static-lb";
    }))
    {
      CNAME = {
        name = "@";
        type = "CNAME";
        target = [ "www.${domain}." ];
      };
    }
  ];
}
