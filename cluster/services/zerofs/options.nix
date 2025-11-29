{ lib, ... }:

with lib;

{
  options.storage.zerofs = {
    fileSystems = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          mountPoint = mkOption {
            type = types.path;
            default = "/srv/${name}";
          };

          s3BucketPath = mkOption {
            type = types.str;
            example = "s3://zerofs-bucket/example/";
          };

          s3Endpoint = mkOption {
            type = types.str;
            example = "https://s3.example.com";
          };

          s3Region = mkOption {
            type = types.str;
            default = "us-east-1";
          };
        };
      }));
      default = { };
    };
  };
}
