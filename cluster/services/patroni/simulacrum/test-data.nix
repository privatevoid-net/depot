{ config, lib, ... }:
{
  patroni = lib.mkIf config.simulacrum {
    databases = config.lib.forService "patroni" {
      testdb.owner = "testuser";
      existingdb.owner = "existinguser";
    };
    users = config.lib.forService "patroni" {
      testuser.locksmith = {
        nodes = config.services.patroni.nodes.haproxy;
        format = "pgpass";
      };
      existinguser.locksmith = {
        nodes = config.services.patroni.nodes.haproxy;
        format = "pgpass";
      };
    };
  };
}
