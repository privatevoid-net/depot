{ depot, ... }:

{
  services.soda = {
    nodes.host = [ "VEGAS" ];
    nixos.host = ./host.nix;
  };

  monitoring.blackbox.targets.soda-machine = {
    address = "soda.int.${depot.lib.meta.domain}:22";
    module = "sshConnect";
  };

  dns.records = {
    soda.target = [ depot.hours.VEGAS.interfaces.primary.addrPublic ];
    "soda.int".target = [ "10.10.2.206" ];
  };
}
