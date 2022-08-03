{ cluster, config, ... }:
let
  inherit (config.networking) hostName;

  link = cluster.config.links."mesh-node-${hostName}";

  mkPeer = peerName: let
    peerLink = cluster.config.links."mesh-node-${peerName}";
  in {
    publicKey = peerLink.extra.pubKey;
    allowedIPs = [ "${peerLink.extra.meshIp}/32" ];
    endpoint = peerLink.tuple;
  };
in
{
  age.secrets.wireguard-key-core = {
    file = link.extra.privKeyFile;
    mode = "0400";
  };

  networking = {
    firewall = {
      allowedUDPPorts = [ link.port ];
    };

    wireguard = {
      enable = true;
      interfaces.wgmesh = {
        ips = [ "${link.extra.meshIp}/24" ];
        listenPort = link.port;
        privateKeyFile = config.age.secrets.wireguard-key-core.path;
        peers = map mkPeer cluster.config.services.wireguard.otherNodes.mesh;
      };
    };
  };
}
