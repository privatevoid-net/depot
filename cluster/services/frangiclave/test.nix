{ lib, ... }:

{
  interactive.defaults = { cluster, config, ... }: {
    config = lib.mkIf config.services.vault.enable {
      environment.variables.VAULT_ADDR = cluster.config.hostLinks.${config.networking.hostName}.frangiclave-server.url;
      environment.systemPackages = [ config.services.vault.package ];
    };
  };

  testScript = "assert False";
}
