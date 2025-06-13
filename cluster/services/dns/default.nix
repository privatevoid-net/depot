{ config, depot, lib, ... }:

let
  inherit (depot) hours;
  cfg = config.services.dns;
in
{
  imports = [
    ./options.nix
    ./nodes.nix
    ./ns-records.nix
  ];

  links = {
    dnsResolver = {
      ipv4 = hours.VEGAS.interfaces.vstub.addr;
      port = 53;
    };
    acmeDnsApi = {
      hostname = "acme-dns-challenge.internal.${depot.lib.meta.domain}";
      protocol = "http";
    };
  };
  hostLinks = lib.mkMerge [
    (lib.genAttrs cfg.nodes.authoritative (node: {
      dnsAuthoritative = {
        ipv4 = hours.${node}.interfaces.primary.addrPublic;
        port = 53;
      };
      acmeDnsApi = {
        ipv4 = config.vars.mesh.${node}.meshIp;
        inherit (config.links.acmeDnsApi) port;
        protocol = "http";
      };
    }))
    (lib.genAttrs cfg.nodes.coredns (node: {
      dnsResolver = {
        ipv4 = config.vars.mesh.${node}.meshIp;
        port = 53;
      };
    }))
    (lib.genAttrs cfg.nodes.coredns (node: {
      dnsResolverBackend = {
        ipv4 = config.vars.mesh.${node}.meshIp;
      };
    }))
  ];
  services.dns = {
    nodes = {
      authoritative = [ "VEGAS" "checkmate" "prophet" ];
      coredns = [ "checkmate" "VEGAS" ];
      client = [ "checkmate" "grail" "thunderskin" "VEGAS" "prophet" ];
    };
    nixos = {
      authoritative = ./authoritative.nix;
      coredns = ./coredns.nix;
      client = ./client.nix;
    };
    simulacrum = {
      enable = true;
      deps = [ "consul" "acme-client" "patroni" ];
      settings = ./test.nix;
    };
  };

  patroni = {
    databases.acmedns = {};
    users.acmedns = {
      locksmith = {
        nodes = config.services.dns.nodes.authoritative;
        format = "envFile";
      };
    };
  };

  dns.records = {
    securedns.consulService = "securedns";
    securedns-CAA = {
      name = "securedns";
      type = "CAA";
      target = [
        "0 issue \"buypass.no\""
        "0 issuewild \";\""
        "0 iodef \"mailto:${depot.lib.meta.adminEmail}\""
      ];
    };
    "acme-dns-challenge.internal".consulService = "acme-dns";
  };
}
