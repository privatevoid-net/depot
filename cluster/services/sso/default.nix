{ depot, ... }:

{
  services.sso = {
    nodes.host = [ "VEGAS" ];
    nixos.host = ./host.nix;
  };

  dns.records = let
    ssoAddr = [ depot.hours.VEGAS.interfaces.primary.addrPublic ];
  in {
    login.target = ssoAddr;
    account.target = ssoAddr;
  };
}
