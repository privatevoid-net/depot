{ config, depot, lib, ... }:

let
  inherit (depot) hours;
  cfg = config.services.dns;
in
{
  imports = [
    ./options.nix
  ];

  vars.pdns-api-key-secret = {
    file = ./pdns-api-key.age;
    mode = "0400";
  };
  links = {
    dnsResolver = {
      ipv4 = hours.VEGAS.interfaces.vstub.addr;
      port = 53;
    };
    powerdns-api = {
      ipv4 = config.vars.mesh.VEGAS.meshIp;
      protocol = "http";
    };
  };
  hostLinks = lib.mkMerge [
    (lib.genAttrs (with cfg.nodes; master ++ slave) (node: {
      dnsAuthoritative = {
        ipv4 = hours.${node}.interfaces.primary.addrPublic;
        port = 53;
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
      master = [ "VEGAS" ];
      slave = [ "checkmate" "prophet" ];
      coredns = [ "checkmate" "VEGAS" ];
      client = [ "checkmate" "thunderskin" "VEGAS" "prophet" ];
    };
    nixos = {
      master = [
        ./authoritative.nix
        ./admin.nix
      ];
      slave = ./authoritative.nix;
      coredns = ./coredns.nix;
      client = ./client.nix;
    };
  };
}
