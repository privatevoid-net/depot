{ config, depot, lib, ... }:

let
  inherit (depot) hours;
  cfg = config.services.dns;
in
{
  imports = [
    ./options.nix
    ./nodes.nix
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
  };

  dns.records = {
    securedns.consulService = "securedns";
    "acme-dns-challenge.internal".consulService = "acme-dns";
  };
}
