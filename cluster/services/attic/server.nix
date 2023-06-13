{ config, depot, lib, tools, ... }:

let
  dataDir = "/srv/storage/private/attic";
in

{
  imports = [
    depot.inputs.attic.nixosModules.atticd
  ];

  age.secrets.atticServerToken.file = ./attic-server-token.age;

  links.atticServer.protocol = "http";

  services.atticd = {
    enable = true;

    credentialsFile = config.age.secrets.atticServerToken.path;

    settings = {
      listen = config.links.atticServer.tuple;

      chunking = {
        nar-size-threshold = 512 * 1024;
        min-size = 64 * 1024;
        avg-size = 512 * 1024;
        max-size = 1024 * 1024;
      };

      database.url = "sqlite://${dataDir}/server.db?mode=rwc";

      storage = {
        type = "local";
        path = "${dataDir}/chunks";
      };
    };
  };

  users = {
    users.atticd = {
      isSystemUser = true;
      group = "atticd";
      home = dataDir;
      createHome = true;
    };
    groups.atticd = {};
  };

  systemd.services.atticd.serviceConfig.DynamicUser = lib.mkForce false;

  services.nginx.virtualHosts."cache-api.${tools.meta.domain}" = tools.nginx.vhosts.proxy config.links.atticServer.url;
}
