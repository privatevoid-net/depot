{ config, lib, pkgs, tools, ... }:
with tools.nginx;
let
  inherit (tools.meta) domain;
  cfg = config.services.ipfs;
  ipfsApi = pkgs.writeTextDir "api" "/ip4/127.0.0.1/tcp/5001";
in
{
  networking.firewall = {
    allowedTCPPorts = [ 4001 ];
    allowedUDPPorts = [ 4001 ];
  };

  services.ipfs = {
    enable = true;
    startWhenNeeded = false;
    autoMount = true;

    gatewayAddress = "/ip4/127.0.0.1/tcp/48280";
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

  systemd.services.ipfs = {
    environment.LIBP2P_FORCE_PNET = "1";
    serviceConfig.Slice = "remotefshost.slice";
  };

  environment.variables.IPFS_PATH = lib.mkForce "${ipfsApi}";

  environment.shellAliases = {
    ipfs-admin = "sudo -u ${cfg.user} env IPFS_PATH=${cfg.dataDir} ipfs";
  };

  services.nginx.virtualHosts = {
    "top-level.${domain}".locations = {
      "~ ^/ip[fn]s" = {
        proxyPass = "http://127.0.0.1:48280";
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
          proxyPass = "http://127.0.0.1:48280";
          extraConfig = ''
            add_header X-Content-Type-Options "";
            add_header Access-Control-Allow-Origin *;
          '';
        };
        "/ipfs".extraConfig = "expires max;";
      };
    };
    "ipfs.admin.${domain}" = vhosts.basic // {
      locations."/api".proxyPass = "http://127.0.0.1:5001";
      locations."/ipns/webui.ipfs.${domain}".proxyPass = "http://127.0.0.1:48280/ipns/webui.ipfs.${domain}";
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
        proxyPass = "http://127.0.0.1:48280";
        extraConfig = ''
          add_header X-Content-Type-Options "";
          add_header Access-Control-Allow-Origin *;
        '';
      };
    };
  };
}
