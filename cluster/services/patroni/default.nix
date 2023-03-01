{ config, lib, ... }:

let
  cfg = config.services.patroni;

  renameToLink = mode: n: lib.nameValuePair "patroni-etcd-node-${mode}-${n}";

  genLinks = mode: nodes: f: lib.mapAttrs' (renameToLink mode) (lib.genAttrs nodes f);

  getMeshIp = name: config.vars.mesh.${name}.meshIp;

  mkLink = name: {
    ipv4 = getMeshIp name;
    protocol = "http";
  };
in
{
  vars.patroni = {
    etcdNodes = lib.genAttrs cfg.nodes.etcd (name: config.links."patroni-etcd-node-peer-${name}");
    etcdNodesClient = lib.genAttrs cfg.nodes.etcd (name: config.links."patroni-etcd-node-client-${name}");
    passwords = {
      PATRONI_REPLICATION_PASSWORD = ./passwords/replication.age;
      PATRONI_SUPERUSER_PASSWORD = ./passwords/superuser.age;
      PATRONI_REWIND_PASSWORD = ./passwords/rewind.age;
    };
  };
  links = genLinks "client" cfg.nodes.etcd mkLink
    // genLinks "peer" cfg.nodes.etcd mkLink
    // {
    patroni-pg-internal.ipv4 = "0.0.0.0";
    patroni-api.ipv4 = "0.0.0.0";
    patroni-pg-access.ipv4 = "127.0.0.1";
  };
  services.patroni = {
    nodes = {
      worker = [ "VEGAS" "prophet" ];
      etcd = [ "checkmate" "VEGAS" "prophet" ];
      haproxy = [ "VEGAS" "prophet" ];
    };
    nixos = {
      worker = ./worker.nix;
      etcd = ./etcd.nix;
      haproxy = ./haproxy.nix;
    };
  };
}
