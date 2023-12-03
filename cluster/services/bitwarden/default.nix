{ depot, ... }:

{
  dns.records.keychain.target = [ depot.hours.VEGAS.interfaces.primary.addrPublic ];
}
