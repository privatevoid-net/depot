{ cluster, config, depot, pkgs, ... }:

let
  inherit (depot.lib.meta) domain;
  inherit (cluster.config.services.gotosocial) secrets;
  oidcBaseUrl = "https://login.${domain}";
  oidcUrl = "${oidcBaseUrl}/auth/realms/master";
  link = cluster.config.hostLinks.${config.networking.hostName}.gotosocial;
in

{
  services.gotosocial = {
    enable = true;
    setupPostgresqlDB = true;
    settings = {
      application-name = "TRVKE Social";
      host = "trvke.social";
      bind-address = link.ipv4;
      inherit (link) port;
      trusted-proxies = [ "10.1.1.0/24" ];
      oidc-enabled = true;
      oidc-idp-name = "Private Void Account";
      oidc-issuer = oidcUrl;
      oidc-allowed-groups = [ "/trvkesocialusers@${domain}" ];
      oidc-admin-groups = [ "/trvkesocialadmins@${domain}" ];
    };
    environmentFile = secrets.secrets.path;
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
  };
}
