{ aspect, config, inputs, lib, pkgs, tools, ... }:

let
  inherit (tools.meta) domain;
  inherit (tools.nginx) vhosts;
  cfg = config.services.ipfs-cluster;
  ipfsCfg = config.services.ipfs;

  apiSocket = "/run/ipfs-cluster/ipfs-cluster-api.sock";
  pinSvcSocket = "/run/ipfs-cluster/ipfs-pinning-service-api.sock";
  proxySocket = "/run/ipfs-cluster/ipfs-api-proxy.sock";
in {
  imports = [
    aspect.modules.ipfs-cluster
  ];

  age.secrets = {
    ipfs-cluster-secret.file = ./cluster-secret.age;
    ipfs-cluster-pinsvc-credentials = {
      file = ./cluster-pinsvc-credentials.age;
      owner = cfg.user;
    };
  };

  services.ipfs-cluster = {
    enable = true;
    package = inputs.self.packages.${pkgs.system}.ipfs-cluster;
    consensus = "crdt";
    dataDir = "/srv/storage/ipfs/cluster";
    secretFile = config.age.secrets.ipfs-cluster-secret.path;
    pinSvcBasicAuthFile = config.age.secrets.ipfs-cluster-pinsvc-credentials.path;
    openSwarmPort = true;
    settings = {
      cluster = {
        peer_addresses = [
          "/ip4/95.216.8.12/tcp/9096/p2p/12D3KooWFqccQN24XbpJbguWmtqAJwKarPXxMNqGCz1wSQqKL97D"
          "/ip4/152.67.79.222/tcp/9096/p2p/12D3KooWC7y9GH5j6zioqGx6354WfWwKCQAKbRMDJY2gJ5j5qLzm"
        ];
        replication_factor_min = 1;
        replication_factor_max = 2;
      };
      api = {
        ipfsproxy = {
          listen_multiaddress = "/unix${proxySocket}";
          node_multiaddress = ipfsCfg.apiAddress;
        };
        pinsvcapi.http_listen_multiaddress = "/unix${pinSvcSocket}";
        restapi.http_listen_multiaddress = "/unix${apiSocket}";
      };
      ipfs_connector.ipfshttp.node_multiaddress = ipfsCfg.apiAddress;
    };
  };

  systemd.services.ipfs-cluster = {
    postStart = ''
      chmod 0660 ${apiSocket} ${pinSvcSocket} ${proxySocket}
    '';
    serviceConfig = {
      IPAddressDeny = [
        "10.0.0.0/8"
        "100.64.0.0/10"
        "169.254.0.0/16"
        "172.16.0.0/12"
        "192.0.0.0/24"
        "192.0.2.0/24"
        "192.168.0.0/16"
        "198.18.0.0/15"
        "198.51.100.0/24"
        "203.0.113.0/24"
        "240.0.0.0/4"
        "100::/64"
        "2001:2::/48"
        "2001:db8::/32"
        "fc00::/7"
        "fe80::/10"
      ];
    };
  };

  services.nginx.virtualHosts."pin.${domain}" = vhosts.proxy "http://unix:${pinSvcSocket}";
  users.users.nginx.extraGroups = [ cfg.group ];
  security.acme.certs."pin.${domain}" = {
    dnsProvider = "pdns";
    webroot = lib.mkForce null;
  };
}