{ depot, ... }:

{
  services.fbi = {
    nodes.host = [ "VEGAS" ];
    nixos.host = ./host.nix;
  };

  dns.records = let
    fbiAddr = [ depot.hours.VEGAS.interfaces.primary.addrPublic ];
  in {
    fbi-index.target = fbiAddr;
    fbi-requests.target = fbiAddr;
    radarr.target = fbiAddr;
    sonarr.target = fbiAddr;
  };
}
