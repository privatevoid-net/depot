{ config, depot, ... }:

{
  services.bitwarden = {
    nodes.host = [ "VEGAS" ];
    nixos.host = ./host.nix;
  };

  patroni = config.lib.forService "bitwarden" {
    databases.vaultwarden = {};
    users.vaultwarden.locksmith = {
      nodes = config.services.bitwarden.nodes.host;
      format = "envFile";
    };
  };

  dns.records.keychain.target = [ depot.hours.VEGAS.interfaces.primary.addrPublic ];
}
