{ config, depot, ... }:

{
  services.soda = {
    nodes.host = [ "VEGAS" ];
    nixos.host = ./host.nix;
    meshLinks.host.quickie.link.protocol = "http";
  };

  monitoring.blackbox.targets.soda-machine = {
    address = "soda.int.${depot.lib.meta.domain}:22";
    module = "sshConnect";
  };

  dns.records = {
    soda.target = [ depot.hours.VEGAS.interfaces.primary.addrPublic ];
    "soda.int".target = [ "10.10.2.206" ];
  };

  ways = let
    host = builtins.head config.services.forge.nodes.server;
  in config.lib.forService "soda" {
    schizo = {
      target = config.hostLinks.${host}.quickie.url;
      domainSuffix = "cooking";
    };
  };
}
