{ cluster, config, ... }:
let
  inherit (config.networking) hostName;

  link = cluster.config.hostLinks.${hostName}.mesh;

  mkPeer = peerName: let
    peerLink = cluster.config.hostLinks.${peerName}.mesh;
  in {
    publicKey = peerLink.extra.pubKey;
    allowedIPs = [ "${peerLink.extra.meshIp}/32" ] ++ peerLink.extra.extraRoutes;
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
      trustedInterfaces = [ "wgmesh" ];
      allowedUDPPorts = [ link.port ];
    };

    wireguard = {
      enable = true;
      interfaces.wgmesh = {
        ips = [ "${link.extra.meshIp}/24" ];
        listenPort = link.port;
        privateKeyFile = config.age.secrets.wireguard-key-core.path;
        peers = map mkPeer (cluster.config.services.wireguard.otherNodes.mesh hostName);
      };
    };
  };
}
