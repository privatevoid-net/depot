{ depot, ... }:

{
  monitoring.blackbox.targets.soda-machine = {
    address = "soda.int.${depot.lib.meta.domain}:22";
    module = "sshConnect";
  };

  dns.records.soda.target = [ depot.hours.VEGAS.interfaces.primary.addrPublic ];
}
