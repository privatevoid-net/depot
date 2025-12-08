{ config, depot, ... }:

{
  services.sso = {
    nodes = {
      host = [ "grail" ];
      oauth2-proxy = [ "VEGAS" ];
    };
    nixos = {
      host = ./host.nix;
      oauth2-proxy = ./oauth2-proxy.nix;
    };
  };

  dns.records = let
    ssoAddr = [ depot.hours.VEGAS.interfaces.primary.addrPublic ];
  in {
    login.target = ssoAddr;
    account.target = ssoAddr;
  };

  patroni = config.lib.forService "sso" {
    databases.keycloak = {};
    users.keycloak.locksmith = {
      nodes = config.services.sso.nodes.host;
      format = "raw";
    };
  };
}
