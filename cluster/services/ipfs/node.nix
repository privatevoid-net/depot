{ cluster, config, depot, lib, pkgs, ... }:
let
  inherit (depot.lib.meta) domain;
  cfg = config.services.ipfs;
  apiAddress = "/unix/run/ipfs/ipfs-api.sock";
  ipfsApi = pkgs.writeTextDir "api" apiAddress;
  gw = cluster.config.hostLinks.${config.networking.hostName}.ipfsGateway;
  ipfsPort = 110;
  nameservers = lib.unique config.networking.nameservers;
in
{
  imports = [
    depot.nixosModules.ipfs
  ];

  networking.firewall = {
    allowedTCPPorts = [ ipfsPort 4001 ];
    allowedUDPPorts = [ ipfsPort 4001 ];
  };

  services.ipfs = {
    enable = true;
    package = depot.packages.ipfs;
    startWhenNeeded = false;
    autoMount = true;
    autoMigrate = false;

    swarmAddress = [
      "/ip4/0.0.0.0/tcp/${toString ipfsPort}"
      "/ip4/0.0.0.0/tcp/4001"
      "/ip4/0.0.0.0/udp/${toString ipfsPort}/quic-v1"
      "/ip4/0.0.0.0/udp/4001/quic-v1"
    ];
    inherit apiAddress;
    gatewayAddress = "/ip4/${gw.ipv4}/tcp/${gw.portStr}";
    dataDir = "/srv/storage/ipfs/repo";
    localDiscovery = false;

    extraFlags = [ "--migrate" ];
    extraConfig = {
      Bootstrap = [
        "/ip4/${depot.hours.VEGAS.interfaces.primary.addr}/tcp/${toString ipfsPort}/p2p/Qmd7QHZU8UjfYdwmjmq1SBh9pvER9AwHpfwQvnvNo3HBBo"
        "/dnsaddr/bootstrap.libp2p.io/p2p/QmQCU2EcMqAqQPR2i9bChDtGNJchTbq5TbXJJ16u19uLTa"
        "/dnsaddr/bootstrap.libp2p.io/p2p/QmbLHAnMoJPWSCR5Zhtx6BHJX9KiKNN6tpvbUcqanj75Nb"
        "/dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN"
        "/dnsaddr/bootstrap.libp2p.io/p2p/12D3KooWEZXjE41uU4EL2gpkAQeDXYok6wghN7wwNVPF5bwkaNfS"
        "/dnsaddr/bootstrap.libp2p.io/p2p/QmcZf59bWwK5XFi76CZX8cbJ4BhTzzA3gU1ZjYZcYW3dwt"
        "/dnsaddr/bootstrap.libp2p.io/p2p/QmZa1sAxajnQjVM8WjWXoMbmPd7NsWhfKsPkErzpm9wGkp"
      ];
      AutoNAT.ServiceMode = "enabled";
      API.HTTPHeaders = {
        Access-Control-Allow-Origin = [
          "https://ipfs.admin.${domain}"
          "http://127.0.0.1:5001"
        ];
        Access-Control-Allow-Methods = [ "PUT" "POST" ];
      };
      Peering.Peers = map
        (name: let inherit (cluster.config.hostLinks.${name}.ipfs) extra; in {
          ID = extra.peerId;
          Addrs = extra.multiaddrs;
        })
        (cluster.config.services.ipfs.otherNodes.node config.networking.hostName);
      Gateway = {
        Writable = false;
        ExposeRoutingAPI = true;
        APICommands = [];
        HTTPHeaders = {
          Access-Control-Allow-Headers = [
            "X-Requested-With"
            "Range"
            "User-Agent"
          ];
          Access-Control-Allow-Methods = [
            "GET"
          ];
          Access-Control-Allow-Origin = [
            "*"
          ];
        };
      };
      Routing = {
        Type = "custom";
        Routers = {
          WanDHT = {
            Type = "dht";
            Parameters = {
              Mode = "auto";
              PublicIPNetwork = true;
              AcceleratedDHTClient = true;
            };
          };
          CidContact = {
            Type = "http";
            Parameters.Endpoint = "https://cid.contact";
          };
          Parallel = {
            Type = "parallel";
            Parameters.Routers = [
              {
                RouterName = "WanDHT";
                IgnoreErrors = false;
                Timeout = "5m";
              }
              {
                RouterName = "CidContact";
                IgnoreErrors = true;
                Timeout = "3s";
                ExecuteAfter = "1s";
              }
            ];
          };
        };
        Methods = {
          find-peers.RouterName = "Parallel";
          find-providers.RouterName = "Parallel";
          get-ipns.RouterName = "Parallel";
          put-ipns.RouterName = "Parallel";
          provide.RouterName = "WanDHT";
        };
      };
    };
  };

  systemd.sockets = {
    ipfs-api.enable = false;
    ipfs-gateway.enable = false;
  };

  systemd.tmpfiles.rules = [
    "d '/run/ipfs' 0750 ${cfg.user} ${cfg.group} - -"
  ];


  systemd.services.ipfs = {
    strictMounts = [ cfg.dataDir ];
    serviceConfig = {
      Slice = "remotefshost.slice";
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
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
      IPAddressAllow = nameservers ++ [
        cluster.config.vars.meshNet.cidr
      ];
    };
    postStart = "chmod 660 /run/ipfs/ipfs-api.sock";
  };

  environment.variables.IPFS_PATH = lib.mkForce "${ipfsApi}";

  environment.shellAliases = {
    ipfs-admin = "sudo -u ${cfg.user} env IPFS_PATH=${cfg.dataDir} ipfs";
  };
}
