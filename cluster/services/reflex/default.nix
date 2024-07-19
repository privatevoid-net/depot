{ depot, ... }:

{
  services.reflex = {
    nodes.host = [ "VEGAS" ];
    nixos.host = ./host.nix;
  };

  dns.records.reflex.target = [ depot.hours.VEGAS.interfaces.primary.addrPublic ];
}
