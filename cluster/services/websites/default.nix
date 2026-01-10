{ config, depot, lib, ... }:

let
  inherit (depot.lib.meta) domain;

  acmeUseDNS = name: conf: {
    name = conf.useACMEHost or conf.serverName or name;
    value = {
      dnsProvider = "exec";
      webroot = null;
    };
  };

  isACME = _: conf: conf ? enableACME && conf.enableACME;
in

{
  services.websites = {
    nodes = {
      host = [ "checkmate" "thunderskin" "VEGAS" "prophet" ];
      oldStatic = [ "VEGAS" ];
    };
    nixos.oldStatic = [
      ./old-static
      ./old-static/jokes.nix
    ];
    nixos.host = { config, depot, depot', ... }: let

      importWebsites = expr: import expr {
        tools = depot.lib.nginx;
        inherit (depot') inputs packages;
      };

      websites = depot.lib.nginx.mappers.mapSubdomains (importWebsites ./websites.nix);

    in {
      services.nginx.virtualHosts = websites;
      security.acme.certs = lib.mapAttrs' acmeUseDNS (lib.filterAttrs isACME websites);
      consul.services.nginx = {
        mode = "external";
        definition = {
          name = "static-lb";
          address = config.reflection.interfaces.primary.addrPublic;
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

  dns.records = let
    oldStaticAddr = [ depot.hours.VEGAS.interfaces.primary.addrPublic ];
  in lib.mkMerge [
    (lib.genAttrs [ "www" "draw" "stop-using-nix-env" "whoami" "docs.hyprspace" ] (lib.const {
      consulService = "static-lb";
    }))
    {
      top-level = {
        name = "@";
        consulService = "static-lb";
      };

      autoconfig.target = oldStaticAddr;

      ktp.target = oldStaticAddr;
      legacy.target = oldStaticAddr;

      # jokes
      "bone-ds-dc.com-ldap".target = oldStaticAddr;
      rzentrale.target = oldStaticAddr;
      wunschnachricht.target = oldStaticAddr;
    }
  ];

  ways = config.lib.forService "websites" {
    bomed = {
      static = { depot', ... }: depot'.packages.ldap-entry-point.webroot;
      domainSuffix = "lol";
    };
  };
}
