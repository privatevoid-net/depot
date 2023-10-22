{ pkgs, depot, lib, config, ... }:
let
  inherit (config.networking) hostName;
  inherit (depot.packages) hyprspace;
  hyprspaceCapableNodes = lib.filterAttrs (_: host: host.hyprspace.enable) depot.hours;
  peersFormatted = builtins.mapAttrs (_: x: {
    inherit (x.hyprspace) id;
    routes = map (net: { inherit net; }) ((x.hyprspace.routes or []) ++ [ "${x.hyprspace.addr}/32" ]);
  }) hyprspaceCapableNodes;
  peersFiltered = lib.filterAttrs (name: _: name != hostName) peersFormatted;
  peerList = builtins.attrValues peersFiltered;
  myNode = depot.reflection;
  listenPort = myNode.hyprspace.listenPort or 8001;

  interfaceConfig = pkgs.writeText "hyprspace.yml" (builtins.toJSON {
    interface = {
      name = "hyprspace";
      listen_port = listenPort;
      inherit (myNode.hyprspace) id;
      address = "${myNode.hyprspace.addr}/24";
      private_key = "@HYPRSPACEPRIVATEKEY@";
    };
    peers = peerList;
  });

  privateKeyFile = config.age.secrets.hyprspace-key.path;
  runConfig = "/run/hyprspace.yml";
  nameservers = lib.unique config.networking.nameservers;
in {
  links.hyprspaceMetrics.protocol = "http";

  networking.hosts = lib.mapAttrs' (k: v: lib.nameValuePair v.hyprspace.addr [k "${k}.hypr"]) hyprspaceCapableNodes;
  age.secrets.hyprspace-key = {
    file = ../../secrets/hyprspace-key- + "${hostName}.age";
    mode = "0400";
  };

  systemd.services.hyprspace = {
    enable = true;
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    preStart = ''
      test -e ${runConfig} && rm ${runConfig}
      cp ${interfaceConfig} ${runConfig}
      chmod 0600 ${runConfig}
      ${pkgs.replace-secret}/bin/replace-secret '@HYPRSPACEPRIVATEKEY@' "${privateKeyFile}" ${runConfig}
      chmod 0400 ${runConfig}
    '';
    environment.HYPRSPACE_METRICS_PORT = config.links.hyprspaceMetrics.portStr;
    serviceConfig = {
      Group = "wheel";
      Restart = "on-failure";
      RestartSec = "5s";
      ExecStart = "${hyprspace}/bin/hyprspace up hyprspace -f -c ${runConfig}";
      ExecStop = "${hyprspace}/bin/hyprspace down hyprspace";
      ExecStopPost = "${pkgs.coreutils}/bin/rm -f /run/hyprspace-rpc.hyprspace.sock";
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
      IPAddressAllow = nameservers;
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ listenPort ];
    allowedUDPPorts = [ listenPort ];
    trustedInterfaces = [ "hyprspace" ];
  };

  environment.systemPackages = [
    hyprspace
  ];

  services.grafana-agent.settings.metrics.configs = lib.singleton {
    name = "metrics-hyprspace";
    scrape_configs = lib.singleton {
      job_name = "hyprspace";
      static_configs = lib.singleton {
        targets = lib.singleton config.links.hyprspaceMetrics.tuple;
        labels = {
          instance = hostName;
          peer_id = myNode.hyprspace.id;
        };
      };
    };
  };
}
