{ depot, ... }:

{
  dns.records = let
    ssoAddr = [ depot.hours.VEGAS.interfaces.primary.addrPublic ];
  in {
    login.target = ssoAddr;
    account.target = ssoAddr;
  };
}
