{ aspect, config, inputs, lib, hosts, pkgs, tools, ... }:
let
  inherit (tools.meta) domain;
  cfg = config.services.ipfs;
  apiAddress = "/unix/run/ipfs/ipfs-api.sock";
  ipfsApi = pkgs.writeTextDir "api" apiAddress;
  gw = config.links.ipfsGateway;
  ipfsPort = 110;
in
{
  imports = [
    aspect.modules.ipfs
  ];

  links.ipfsGateway.protocol = "http";

  networking.firewall = {
    allowedTCPPorts = [ ipfsPort 4001 ];
    allowedUDPPorts = [ ipfsPort 4001 ];
  };

  services.ipfs = {
    enable = true;
    package = inputs.self.packages.${pkgs.system}.ipfs;
    startWhenNeeded = false;
    autoMount = true;
    autoMigrate = false;

    swarmAddress = [
      "/ip4/0.0.0.0/tcp/${toString ipfsPort}"
      "/ip4/0.0.0.0/tcp/4001"
      "/ip4/0.0.0.0/udp/${toString ipfsPort}/quic"
      "/ip4/0.0.0.0/udp/4001/quic"
    ];
    inherit apiAddress;
    gatewayAddress = "/ip4/${gw.ipv4}/tcp/${gw.portStr}";
    dataDir = "/srv/storage/ipfs/repo";
    localDiscovery = false;

    extraFlags = [ "--migrate" ];
    extraConfig = {
      Bootstrap = [
        "/ip4/${hosts.VEGAS.interfaces.primary.addr}/tcp/${toString ipfsPort}/p2p/Qmd7QHZU8UjfYdwmjmq1SBh9pvER9AwHpfwQvnvNo3HBBo"
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
      Gateway = {
        Writable = false;
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
    serviceConfig = {
      Slice = "remotefshost.slice";
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
    };
    postStart = "chmod 660 /run/ipfs/ipfs-api.sock";
  };

  environment.variables.IPFS_PATH = lib.mkForce "${ipfsApi}";

  environment.shellAliases = {
    ipfs-admin = "sudo -u ${cfg.user} env IPFS_PATH=${cfg.dataDir} ipfs";
  };
}
