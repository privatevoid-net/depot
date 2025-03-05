{ cluster, config, depot, lib, ... }:

let
  inherit (cluster.config.services.attic) secrets;

  link = cluster.config.hostLinks.${config.networking.hostName}.attic;

  isMonolith = lib.elem config.networking.hostName cluster.config.services.attic.nodes.monolith;
in

{
  services.locksmith.waitForSecrets.atticd = [ "garage-attic" "patroni-attic" ];

  services.atticd = {
    enable = true;
    package = depot.inputs.attic.packages.attic-server;

    environmentFile = secrets.serverToken.path;
    mode = if isMonolith then "monolithic" else "api-server";

    settings = {
      listen = link.tuple;

      chunking = {
        nar-size-threshold = 0;
        min-size = 0;
        avg-size = 0;
        max-size = 0;
      };

      compression.type = "none";

      database.url = "postgresql://attic@${cluster.config.links.patroni-pg-access.tuple}/attic";

      storage = {
        type = "s3";
        region = "us-east-1";
        endpoint = cluster.config.links.garageS3.url;
        bucket = "attic";
      };

      garbage-collection = {
        interval = "2 weeks";
        default-retention-period = "3 months";
      };
    };
  };

  users = {
    users.atticd = {
      isSystemUser = true;
      group = "atticd";
      home = "/var/lib/atticd";
      createHome = true;
    };
    groups.atticd = {};
  };

  systemd.services.atticd = {
    after = [ "postgresql.service" ];
    distributed = lib.mkIf isMonolith {
      enable = true;
      registerService = "atticd";
    };
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" ];
      SystemCallFilter = lib.mkAfter [ "@resources" ];
    };
    environment = {
      AWS_SHARED_CREDENTIALS_FILE = "/run/locksmith/garage-attic";
      PGPASSFILE = "/run/locksmith/patroni-attic";
    };
  };

  consul.services.atticd = {
    mode = if isMonolith then "manual" else "direct";
    definition = {
      name = "atticd";
      id = "atticd-${config.services.atticd.mode}";
      address = link.ipv4;
      inherit (link) port;
      checks = [
        {
          name = "Attic Server";
          id = "service:atticd:backend";
          interval = "5s";
          http = link.url;
        }
      ];
    };
  };
}
