{ cluster, config, depot, lib, ... }:

let
  inherit (cluster.config) vars;
  inherit (config.networking) hostName;

  links = cluster.config.hostLinks.${hostName};

  cfg = config.services.garage;

  # fixed uid so we know how to mount the underlay
  uid = 777;
  gid = 777;
in

{
  age.secrets.garageRpcSecret = {
    file = ./secrets/garage-rpc-secret.age;
    owner = "garage";
    group = "garage";
  };

  services.garage = {
    enable = true;
    package = depot.packages.garage;
    settings = {
      replication_mode = "2-dangerous";
      block_size = 16 * 1024 * 1024;
      db_engine = "lmdb";
      metadata_dir = "/var/lib/garage-metadata";
      rpc_bind_addr = links.garageRpc.tuple;
      rpc_public_addr = links.garageRpc.tuple;
      rpc_secret_file = config.age.secrets.garageRpcSecret.path;
      consul_discovery = {
        consul_http_addr = "http://127.0.0.1:8500";
        api = "agent";
        service_name = "garage-discovery";
      };
      s3_api = {
        api_bind_addr = links.garageS3.tuple;
        s3_region = "us-east-1";
      };
    };
  };

  users = {
    users.garage = {
      inherit uid;
      group = "garage";
    };
    groups.garage = {
      inherit gid;
    };
  };

  systemd.services.garage = {
    unitConfig = {
      RequiresMountsFor = [ cfg.settings.data_dir ];
    };
    serviceConfig = {
      IPAddressDeny = [ "any" ];
      IPAddressAllow = [ "127.0.0.1/8" vars.meshNet.cidr ];
      DynamicUser = false;
      PrivateTmp = true;
      ProtectSystem = true;
      User = "garage";
      Group = "garage";
      StateDirectory = lib.removePrefix "/var/lib/" cfg.settings.metadata_dir;
    };
  };
}
