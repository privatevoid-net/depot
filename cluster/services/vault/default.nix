{ depot, ... }:

{
  dns.records.vault.target = [ depot.hours.VEGAS.interfaces.primary.addrPublic ];
}
