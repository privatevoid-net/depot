{ pkgs, inputs, lib, hosts, config, ... }:
let
  inherit (config.networking) hostName;
  inherit (inputs.self.packages.${pkgs.system}) hyprspace;
  hyprspaceCapableNodes = lib.filterAttrs (_: host: host ? hypr) hosts;
  peersFormatted = builtins.mapAttrs (_: x: { "${x.hypr.addr}".id = x.hypr.id; }) hyprspaceCapableNodes;
  peersFiltered = lib.filterAttrs (name: _: name != hostName) peersFormatted;
  buildHyprspacePeerList = peers: pkgs.writeText "hyprspace-peers.yml" (builtins.toJSON peers);
  peerList = buildHyprspacePeerList (lib.foldAttrs (n: _: n) null (builtins.attrValues peersFiltered));
  myNode = hosts.${hostName};
  listenPort = myNode.hypr.listenPort or 8001;

  precedingConfig = pkgs.writeText "hyprspace-interface.yml" ''
    interface:
      name: hyprspace
      listen_port: ${builtins.toString listenPort}
      id: ${myNode.hypr.id}
      address: ${myNode.hypr.addr}/24
      private_key: !!binary |
  '';

  privateKeyFile = config.age.secrets.hyprspace-key.path;
  discoverKey = config.age.secrets.hyprspace-discover-key.path;
  runConfig = "/run/hyprspace.yml";
in {
  networking.hosts = lib.mapAttrs' (k: v: lib.nameValuePair v.hypr.addr [k "${k}.hypr"]) hyprspaceCapableNodes;
  age.secrets.hyprspace-key = {
    file = ../../secrets/hyprspace-key- + "${hostName}.age";
    mode = "0400";
  };
  systemd.services.hyprspace = {
    enable = true;
    after = [ "network-online.target" "ipfs.service" ];
    wantedBy = [ "multi-user.target" ];
    preStart = ''
      test -e ${runConfig} && rm ${runConfig}
      touch ${runConfig}
      chmod 0600 ${runConfig}

      cat ${precedingConfig} >> ${runConfig}
      sed 's/^/    /g' ${privateKeyFile} >> ${runConfig}
      echo -n 'peers: ' >> ${runConfig}
      cat ${peerList} >> ${runConfig}

      chmod 0400 ${runConfig}
    '';
    environment.HYPRSPACE_SWARM_KEY = config.age.secrets.ipfs-swarm-key.path;
    serviceConfig = {
      ExecStart = "${hyprspace}/bin/hyprspace up hyprspace -f -c ${runConfig}";
      ExecStop = "${hyprspace}/bin/hyprspace down hyprspace";
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
  networking.firewall = {
    allowedTCPPorts = [ listenPort ];
    allowedUDPPorts = [ listenPort ];
    trustedInterfaces = [ "hyprspace" ];
  };
}
