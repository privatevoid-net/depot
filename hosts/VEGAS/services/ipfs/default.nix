{ config, lib, pkgs, tools, ... }:
with tools.nginx;
let
  inherit (tools.meta) domain;
  cfg = config.services.ipfs;
  apiAddress = "/unix/run/ipfs/ipfs-api.sock";
  ipfsApi = pkgs.writeTextDir "api" apiAddress;
  gwPort = config.portsStr.ipfsGateway;
in
{
  reservePortsFor = [ "ipfsGateway" ];

  networking.firewall = {
    allowedTCPPorts = [ 4001 ];
    allowedUDPPorts = [ 4001 ];
  };

  services.ipfs = {
    enable = true;
    startWhenNeeded = false;
    autoMount = true;

    inherit apiAddress;
    gatewayAddress = "/ip4/127.0.0.1/tcp/${gwPort}";
    dataDir = "/srv/storage/ipfs/repo";
    localDiscovery = false;

    extraConfig = {
      Bootstrap = [
        "/ip4/168.235.67.108/tcp/4001/p2p/QmRMA5pWXtfuW1y5w2t9gYxrDDD6bPRLKdWAYnHTeCxZMm"
        "/ip4/51.38.87.150/tcp/4001/p2p/12D3KooWDUgNsoLVauCDpRAo54mc4whoBudgeXQnZZK2iVYhBLCN"
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

  systemd.tmpfiles.rules = [ "d '/run/ipfs' 0750 ${cfg.user} ${cfg.group} - -" ];


  systemd.services.ipfs = {
    environment.LIBP2P_FORCE_PNET = "1";
    serviceConfig.Slice = "remotefshost.slice";
    postStart = "chmod 660 /run/ipfs/ipfs-api.sock";
  };

  systemd.slices.remotefshost.sliceConfig = {
    IOWeight = 5;
    IOReadIOPSMax = [ 
      "/dev/sda 100"
      "/dev/sdb 100"
    ];
    IOWriteIOPSMax = [ 
      "/dev/sda 100"
      "/dev/sdb 100"
    ];
    IODviceLatencyTargetSec = [ 
      "/dev/sda 500ms"
      "/dev/sdb 500ms"
    ];
  };

  environment.variables.IPFS_PATH = lib.mkForce "${ipfsApi}";

  environment.shellAliases = {
    ipfs-admin = "sudo -u ${cfg.user} env IPFS_PATH=${cfg.dataDir} ipfs";
  };

  users.users.nginx.extraGroups = [ cfg.group ];

  services.nginx.virtualHosts = {
    "top-level.${domain}".locations = {
      "~ ^/ip[fn]s" = {
        proxyPass = "http://127.0.0.1:${gwPort}";
        extraConfig = ''
          add_header X-Content-Type-Options "";
          add_header Access-Control-Allow-Origin *;
        '';
      };
    };

    "lain-ipfs.${domain}" = vhosts.basic // {
      locations = {
        "= /".return = "404";
        "~ ^/ip[fn]s" = {
          proxyPass = "http://127.0.0.1:${gwPort}";
          extraConfig = ''
            add_header X-Content-Type-Options "";
            add_header Access-Control-Allow-Origin *;
          '';
        };
        "/ipfs".extraConfig = "expires max;";
      };
    };
    "ipfs.admin.${domain}" = vhosts.basic // {
      locations."/api".proxyPass = "http://unix:/run/ipfs/ipfs-api.sock:";
      locations."/ipns/webui.ipfs.${domain}".proxyPass = "http://127.0.0.1:${gwPort}/ipns/webui.ipfs.${domain}";
      locations."= /".return = "302 /ipns/webui.ipfs.${domain}";
    };
  };
  services.oauth2_proxy.nginx.virtualHosts = [ "ipfs.admin.${domain}" ];

  inherit (tools.acme.dns01) age;

  security.acme.certs."ipfs.${domain}" = {
    domain = "*.ipfs.${domain}";
    extraDomainNames = [ "*.ipns.${domain}" ];
    dnsProvider = "rfc2136";
    group = "nginx";
    inherit (tools.acme.dns01) credentialsFile;
  };

  services.nginx.virtualHosts."ipfs.${domain}" = vhosts.basic // {
    serverName = "~^(.+)\.(ip[fn]s)\.${domain}$";
    enableACME = false;
    useACMEHost = "ipfs.${domain}";
    locations = {
      "/" = {
        proxyPass = "http://127.0.0.1:${gwPort}";
        extraConfig = ''
          add_header X-Content-Type-Options "";
          add_header Access-Control-Allow-Origin *;
        '';
      };
    };
  };
}
