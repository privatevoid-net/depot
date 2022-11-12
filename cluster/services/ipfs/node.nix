{ aspect, config, inputs, lib, pkgs, tools, ... }:
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
    ];
    inherit apiAddress;
    gatewayAddress = "/ip4/${gw.ipv4}/tcp/${gw.portStr}";
    dataDir = "/srv/storage/ipfs/repo";
    localDiscovery = false;

    extraFlags = [ "--migrate" ];
    extraConfig = {
      Bootstrap = [
        "/ip4/168.235.67.108/tcp/4001/p2p/QmRMA5pWXtfuW1y5w2t9gYxrDDD6bPRLKdWAYnHTeCxZMm"
        "/ip4/51.38.87.150/tcp/4001/p2p/12D3KooWDUgNsoLVauCDpRAo54mc4whoBudgeXQnZZK2iVYhBLCN"
        "/ip4/77.54.95.19/tcp/12104/p2p/12D3KooWC1RZxLvAeEFNTZWk1FWc1sZZ3yemF4FNNRYa3X854KJ8"
        "/ip4/95.216.8.12/tcp/${toString ipfsPort}/p2p/Qmd7QHZU8UjfYdwmjmq1SBh9pvER9AwHpfwQvnvNo3HBBo"
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
