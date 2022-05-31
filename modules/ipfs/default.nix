{ config, lib, pkgs, tools, ... }:
let
  inherit (tools.meta) domain;
  cfg = config.services.ipfs;
  apiAddress = "/unix/run/ipfs/ipfs-api.sock";
  ipfsApi = pkgs.writeTextDir "api" apiAddress;
  gwPort = config.portsStr.ipfsGateway;
in
{
  age.secrets.ipfs-swarm-key = {
    file = ../../secrets/ipfs-swarm-key.age;
    mode = "0400";
    owner = cfg.user;
    inherit (cfg) group;
  };

  reservePortsFor = [ "ipfsGateway" ];

  networking.firewall = {
    allowedTCPPorts = [ 4001 ];
    allowedUDPPorts = [ 4001 ];
  };

  services.ipfs = {
    enable = true;
    startWhenNeeded = false;
    autoMount = true;
    autoMigrate = false;

    inherit apiAddress;
    gatewayAddress = "/ip4/127.0.0.1/tcp/${gwPort}";
    dataDir = "/srv/storage/ipfs/repo";
    localDiscovery = false;

    extraConfig = {
      Bootstrap = [
        "/ip4/168.235.67.108/tcp/4001/p2p/QmRMA5pWXtfuW1y5w2t9gYxrDDD6bPRLKdWAYnHTeCxZMm"
        "/ip4/51.38.87.150/tcp/4001/p2p/12D3KooWDUgNsoLVauCDpRAo54mc4whoBudgeXQnZZK2iVYhBLCN"
        "/ip4/77.54.95.19/tcp/12104/p2p/12D3KooWC1RZxLvAeEFNTZWk1FWc1sZZ3yemF4FNNRYa3X854KJ8"
        "/ip4/95.216.8.12/tcp/4001/p2p/Qmd7QHZU8UjfYdwmjmq1SBh9pvER9AwHpfwQvnvNo3HBBo"
      ];
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
    "L+ '${cfg.dataDir}/swarm.key' - - - - ${config.age.secrets.ipfs-swarm-key.path}"
  ];


  systemd.services.ipfs = {
    environment.LIBP2P_FORCE_PNET = "1";
    serviceConfig.Slice = "remotefshost.slice";
    postStart = "chmod 660 /run/ipfs/ipfs-api.sock";
  };

  environment.variables.IPFS_PATH = lib.mkForce "${ipfsApi}";

  environment.shellAliases = {
    ipfs-admin = "sudo -u ${cfg.user} env IPFS_PATH=${cfg.dataDir} ipfs";
  };
}
