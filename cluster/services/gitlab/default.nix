{ depot, ... }:

{
  services.gitlab = {
    nodes.host = [ "VEGAS" ];
    nixos.host = ./host.nix;
  };

  dns.records.git.target = [ depot.hours.VEGAS.interfaces.primary.addrPublic ];
}
