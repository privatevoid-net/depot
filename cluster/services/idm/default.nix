{ config, tools, ... }:

{
  links = {
    idm = {
      ipv4 = "idm.${tools.meta.domain}";
      port = 443;
      protocol = "https";
    };
    ldap = {
      hostname = "idm-ldap.internal.${tools.meta.domain}";
      ipv4 = config.vars.mesh.VEGAS.meshIp;
      port = 636;
      protocol = "ldaps";
    };
  };

  services.idm = {
    nodes = {
      server = [ "VEGAS" ];
      client = [ "checkmate" "VEGAS" "prophet" "soda" "thunderskin" ];
      client-soda = [ "soda" ];
    };
    nixos = {
      server = ./server.nix;
      client = [
        ./client.nix
        ./policies/infra-admins.nix
      ];
      client-soda = [
        ./policies/soda.nix
      ];
    };
  };
}
