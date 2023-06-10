{ tools, ... }:

{
  links.idm = {
    ipv4 = "idm.${tools.meta.domain}";
    port = 443;
    protocol = "https";
  };

  services.idm = {
    nodes = {
      server = [ "VEGAS" ];
      client = [ "checkmate" "VEGAS" "prophet" "thunderskin" ];
    };
    nixos = {
      server = ./server.nix;
      client = ./client.nix;
    };
  };
}
