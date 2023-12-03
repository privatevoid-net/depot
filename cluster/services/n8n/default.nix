{ depot, ... }:

{
  dns.records.api.target = [ depot.hours.VEGAS.interfaces.primary.addrPublic ];
}
