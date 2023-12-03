{ config, depot, ... }:

{
  links = {
    idm = {
      ipv4 = "idm.${depot.lib.meta.domain}";
      port = 443;
      protocol = "https";
    };
    ldap = {
      hostname = "idm-ldap.internal.${depot.lib.meta.domain}";
      ipv4 = config.vars.mesh.VEGAS.meshIp;
      port = 636;
      protocol = "ldaps";
    };
  };

  services.idm = {
    nodes = {
      server = [ "VEGAS" ];
      client = [ "checkmate" "grail" "VEGAS" "prophet" "soda" "thunderskin" ];
      client-soda = [ "soda" ];
    };
    nixos = {
      server = ./server.nix;
      client = [
        ./client.nix
        ./modules/idm-nss-ready.nix
        ./modules/idm-tmpfiles.nix
        ./policies/infra-admins.nix
      ];
      client-soda = [
        ./policies/soda.nix
      ];
    };
  };

  dns.records = let
    serverAddrsPublic =  map
      (node: depot.hours.${node}.interfaces.primary.addrPublic)
      config.services.idm.nodes.server;
    serverAddrsInternal =  map
      (node: config.vars.mesh.${node}.meshIp)
      config.services.idm.nodes.server;
  in {
    idm = {
      type = "A";
      target = serverAddrsPublic;
    };
    "idm-ldap.internal" = {
      type = "A";
      target = serverAddrsInternal;
    };
  };
}
