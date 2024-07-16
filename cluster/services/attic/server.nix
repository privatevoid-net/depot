{ cluster, config, depot, lib, ... }:

let
  inherit (cluster.config.services.attic) secrets;
in

{
  imports = [
    depot.inputs.attic.nixosModules.atticd
  ];

  links.atticServer.protocol = "http";

  services.locksmith.waitForSecrets.atticd = [ "garage-attic" ];

  services.atticd = {
    enable = true;
    package = depot.inputs.attic.packages.attic-server;

    credentialsFile = secrets.serverToken.path;

    settings = {
      listen = config.links.atticServer.tuple;

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
    serviceConfig = {
      DynamicUser = lib.mkForce false;
    };
    environment = {
      AWS_SHARED_CREDENTIALS_FILE = "/run/locksmith/garage-attic";
      PGPASSFILE = secrets.dbCredentials.path;
    };
  };

  services.nginx.virtualHosts."cache-api.${depot.lib.meta.domain}" = depot.lib.nginx.vhosts.proxy config.links.atticServer.url // {
    extraConfig = ''
      client_max_body_size 4G;
    '';
  };
}
