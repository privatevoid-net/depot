{ cluster, config, depot, lib, pkgs, ... }:

let
  inherit (cluster.config.services.zerofs) secrets;
  toml = pkgs.formats.toml { };
in

{
  systemd = {
    services = lib.mapAttrs' (name: fs: let

      link = cluster.config.hostLinks.${config.networking.hostName}."zerofs-${name}";

      zerofsConfig = toml.generate "zerofs-${name}.toml" {
        cache = {
          dir = "\${CACHE_DIRECTORY}";
          disk_size_gb = 10;
          memory_size_gb = 1;
        };

        storage = {
          url = fs.s3BucketPath;
          encryption_password = "\${ZEROFS_KEY}";
        };

        aws = {
          access_key_id = "\${AWS_ACCESS_KEY_ID}";
          secret_access_key = "\${AWS_SECRET_ACCESS_KEY}";
          endpoint = fs.s3Endpoint;
          default_region = fs.s3Region;
        };

        servers.nfs = {
          addresses = assert link.protocol == "nfs"; [ link.tuple ];
        };
      };
    in {
      name = "zerofs-server-${name}";
      value = {
        wantedBy = [ "multi-user.target" ];
        distributed.enable = true;
        serviceConfig = {
          ExecStart = "${depot.packages.zerofs}/bin/zerofs run --config ${zerofsConfig}";
          DynamicUser = true;
          CacheDirectory = "zerofs-${name}";
          EnvironmentFile = secrets."storageCredentials-${name}".path;
          Restart = "on-failure";
          RestartSec = "10s";
        };
      };
    }) cluster.config.storage.zerofs.fileSystems;
  };
}
