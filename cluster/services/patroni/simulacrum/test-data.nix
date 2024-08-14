{ config, lib, ... }:
{
  patroni = lib.mkIf config.simulacrum {
    databases = config.lib.forService "patroni" {
      testdb.owner = "testuser";
    };
    users = config.lib.forService "patroni" {
      testuser.locksmith = {
        nodes = config.services.patroni.nodes.haproxy;
        format = "pgpass";
      };
    };
  };
}
