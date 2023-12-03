{ depot, ... }:

{
  dns.records.git.target = [ depot.hours.VEGAS.interfaces.primary.addrPublic ];
}
