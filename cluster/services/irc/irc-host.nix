{ cluster, config, lib, pkgs, depot, ... }:

let
  inherit (depot.lib.meta) adminEmail;
  inherit (cluster) vars;
  inherit (config.networking) hostName;

  linkGlobalSecure = cluster.config.links.ircSecure;
  link = cluster.config.hostLinks.${hostName}.irc;
  linkSecure = cluster.config.hostLinks.${hostName}.ircSecure;
  otherServers = map mkServer (cluster.config.services.irc.otherNodes.host hostName);
  otherServerFiles = map (builtins.toFile "ngircd-peer.conf") otherServers;
  opers = map mkOper vars.ircOpers;

  mkServer = name: let
    peerLink = cluster.config.hostLinks.${name}.ircSecure;
  in ''
    [Server]
    Name = ${peerLink.hostname}
    Host = ${peerLink.ipv4}
    Port = ${peerLink.portStr}
    MyPassword = @PEER_PASSWORD@
    PeerPassword = @PEER_PASSWORD@
    SSLConnect = yes
    Passive = no
  '';
  
  # oper password is irrelevant, mask ensures security thanks to PAM
  mkOper = name: ''
    [Operator]
    Name = ${name}
    Password = please
    Mask = *!${name}@*
  '';

  serverName = linkSecure.hostname;
  cert = config.security.acme.certs."${serverName}";
  dh = config.security.dhparams.params.ngircd;
in {
  services.ngircd = {
    enable = true;
    config = ''
      [Global]
      Name = ${serverName}
      Info = Private Void IRC - ${hostName}
      Network = PrivateVoidIRC
      AdminInfo1 = Private Void Administrators
      AdminInfo2 = Contact for help
      AdminEmail = ${adminEmail}
      Listen = 0.0.0.0
      Ports = ${link.portStr}
      
      [SSL]
      CertFile = ${cert.directory}/fullchain.pem
      KeyFile = ${cert.directory}/key.pem
      DHFile = ${dh.path}
      Ports = ${linkSecure.portStr}
      
      [Options]
      IncludeDir = /run/ngircd/secrets
      AllowedChannelTypes = #
      CloakHost = %x.cloak.void
      MorePrivacy = yes
      PAM = yes
      PAMIsOptional = yes
      OperCanUseMode = yes
      OperChanPAutoOp = yes
      
      [Channel]
      Name = #general
      Topic = General discussions
      
      ${builtins.concatStringsSep "\n" opers}
    '';
  };
  networking.firewall.allowedTCPPorts = [
    link.port
    linkSecure.port
  ];
  security.dhparams = {
    enable = true;
    params.ngircd.bits = 2048;
  };
  security.acme.certs."${serverName}" = {
    dnsProvider = "pdns";
    group = "ngircd";
    reloadServices = [ "ngircd" ];
    extraDomainNames = [ linkGlobalSecure.ipv4 ];
  };
  security.pam.services.ngircd = {
    text = ''
      # verify IRC users via IDM
      auth required ${pkgs.kanidm}/lib/pam_kanidm.so 
    '';
  };
  age.secrets = { inherit (vars) ircPeerKey; };
  systemd.services.ngircd = {
    after = [ "acme-finished-${serverName}.target" "dhparams-gen-ngircd.service" ];
    wants = [ "acme-finished-${serverName}.target" "dhparams-gen-ngircd.service" ];
    restartTriggers = [ "${config.age.secrets.ircPeerKey.file}" ];
    serviceConfig.RuntimeDirectory = "ngircd";
    preStart = ''
      install -d -m700 /run/ngircd/secrets
      for cfg in ${builtins.concatStringsSep " " otherServerFiles}; do
        install -m600 $cfg /run/ngircd/secrets/
        ${pkgs.replace-secret}/bin/replace-secret '@PEER_PASSWORD@' '${config.age.secrets.ircPeerKey.path}' /run/ngircd/secrets/$(basename $cfg)
      done
    '';
  };

  consul.services.ngircd = {
    definition = {
      name = "irc";
      address = linkSecure.ipv4;
      port = linkSecure.port;
      checks = lib.singleton {
        interval = "60s";
        tcp = "${linkSecure.ipv4}:${linkSecure.portStr}";
      };
    };
  };
}
