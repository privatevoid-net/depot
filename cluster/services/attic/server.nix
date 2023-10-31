{ cluster, config, depot, lib, ... }:

let
  inherit (config.networking) hostName;
in

{
  imports = [
    depot.inputs.attic.nixosModules.atticd
  ];

  age.secrets = {
    atticServerToken.file = ./attic-server-token.age;

    atticDBCredentials = {
      file = ./attic-db-credentials.age;
      owner = "atticd";
    };

    atticS3Credentials = {
      file = ./attic-s3-credentials.age;
      owner = "atticd";
    };
  };

  links.atticServer.protocol = "http";

  services.atticd = {
    enable = true;

    credentialsFile = config.age.secrets.atticServerToken.path;

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
        endpoint = cluster.config.hostLinks.${hostName}.garageS3.url;
        bucket = "attic";
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
    serviceConfig = {
      DynamicUser = lib.mkForce false;
    };
    environment = {
      AWS_SHARED_CREDENTIALS_FILE = config.age.secrets.atticS3Credentials.path;
      PGPASSFILE = config.age.secrets.atticDBCredentials.path;
    };
  };

  services.nginx.virtualHosts."cache-api.${depot.lib.meta.domain}" = depot.lib.nginx.vhosts.proxy config.links.atticServer.url // {
    extraConfig = ''
      client_max_body_size 4G;
    '';
  };
}
