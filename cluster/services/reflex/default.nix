{ depot, ... }:

{
  dns.records.reflex.target = [ depot.hours.VEGAS.interfaces.primary.addrPublic ];
}
