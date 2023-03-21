{ config, ... }:

{
  links = {
    loki-ingest = {
      protocol = "http";
      ipv4 = config.vars.mesh.VEGAS.meshIp;
    };
  };
  services.monitoring = {
    nodes = {
      client = [ "checkmate" "thunderskin" "VEGAS" "prophet" ];
    };
    nixos = {
      client = ./client.nix;
    };
  };
}
