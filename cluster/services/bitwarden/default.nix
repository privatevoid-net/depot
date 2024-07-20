{ depot, ... }:

{
  services.bitwarden = {
    nodes.host = [ "VEGAS" ];
    nixos.host = ./host.nix;
  };

  dns.records.keychain.target = [ depot.hours.VEGAS.interfaces.primary.addrPublic ];
}
