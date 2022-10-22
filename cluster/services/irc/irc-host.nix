{ cluster, config, pkgs, tools, ... }:

let
  inherit (tools.meta) adminEmail;
  inherit (cluster) vars;

  linkGlobalSecure = cluster.config.links.ircSecure;
  link = cluster.config.hostLinks.${vars.hostName}.irc;
  linkSecure = cluster.config.hostLinks.${vars.hostName}.ircSecure;
  otherServers = map mkServer cluster.config.services.irc.otherNodes.host;
  otherServerFiles = map (builtins.toFile "ngircd-peer.conf") otherServers;
  opers = map mkOper [ "max" "num" "ark" ];

  mkServer = name: let
    peerLink = cluster.config.hostLinks.${name}.ircSecure;
  in ''
    [Server]
    Name = ${peerLink.ipv4}
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

  serverName = linkSecure.ipv4;
  cert = config.security.acme.certs."${serverName}";
  dh = config.security.dhparams.params.ngircd;
in {
  services.ngircd = {
    enable = true;
    config = ''
      [Global]
      Name = ${serverName}
      Info = Private Void IRC - ${vars.hostName}
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
      # verify IRC users via SSSD
      auth required ${pkgs.sssd}/lib/security/pam_sss.so
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
}
