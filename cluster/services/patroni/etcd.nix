{ cluster, lib, pkgs, ... }:

let
  inherit (cluster.config) vars;

  getEtcdUrl = name: vars.patroni.etcdNodes.${name}.url;

  mkMember = n: "${n}=${getEtcdUrl n}";
in

{
  services.etcd = {
    enable = true;
    dataDir = "/srv/storage/private/etcd";
    initialCluster = (map mkMember cluster.config.services.patroni.nodes.etcd) ++ vars.patroni.etcdExtraNodes;
    listenPeerUrls = lib.singleton vars.patroni.etcdNodes.${vars.hostName}.url;
    listenClientUrls = lib.singleton vars.patroni.etcdNodesClient.${vars.hostName}.url;
  };
  # run on any architecture
  systemd.services.etcd.environment.ETCD_UNSUPPORTED_ARCH = pkgs.go.GOARCH;
}
