{ cluster, config, lib, depot, ... }:

let
  inherit (depot.lib.meta) domain;

  frontendLink = cluster.config.links.idm;

  backendLink = config.links.idmBackend;

  ldapLink = cluster.config.links.ldap;

  certDir = config.security.acme.certs."internal.${domain}".directory;
in

{
  links.idmBackend.protocol = "https";

  security.acme.certs = {
    "internal.${domain}".reloadServices = [ "kanidm.service" ];
    "idm.${domain}" = {
      dnsProvider = "exec";
      webroot = lib.mkForce null;
    };
  };

  services.kanidm = {
    enableServer = true;
    serverSettings = {
      tls_chain = "${certDir}/fullchain.pem";
      tls_key = "${certDir}/key.pem";
      role = "WriteReplicaNoUI";
      bindaddress = backendLink.tuple;
      ldapbindaddress = "${ldapLink.ipv4}:${ldapLink.portStr}";
      origin = frontendLink.url;
      inherit domain;
      online_backup = {
        versions = 7;
      };
    };
  };

  systemd.services.kanidm.after = [ "acme-selfsigned-internal.${domain}.service" ];

  services.nginx.virtualHosts."idm.${domain}" = lib.recursiveUpdate (depot.lib.nginx.vhosts.proxy backendLink.url) {
    locations."/".extraConfig = ''
      proxy_ssl_name idm-backend.internal.${domain};
      proxy_ssl_trusted_certificate ${certDir}/chain.pem;
    '';
  };
}
