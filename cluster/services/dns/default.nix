{ config, ... }:

let
  inherit (config.vars) hosts;
in
{
  vars.pdns-api-key-secret = {
    file = ./pdns-api-key.age;
    mode = "0400";
  };
  links = {
    dnsResolver = {
      ipv4 = hosts.VEGAS.interfaces.vstub.addr;
      port = 53;
    };
    powerdns-api = {
      ipv4 = config.vars.mesh.VEGAS.meshIp;
      protocol = "http";
    };
  };
  services.dns = {
    nodes = {
      master = [ "VEGAS" ];
      slave = [ "checkmate" "prophet" ];
      coredns = [ "VEGAS" ];
      client = [ "VEGAS" "prophet" ];
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
