{ lib, name, options, ... }:

with lib;

{
  options = {
    internal = mkOption {
      description = "Whether to only make this Way available internally. Will use the internal subdomain.";
      type = types.bool;
      default = false;
    };

    name = mkOption {
      description = "Subdomain name to use.";
      type = types.str;
      default = name;
    };

    target = mkOption {
      type = types.str;
    };

    consulService = mkOption {
      type = types.str;
    };

    healthCheckPath = mkOption {
      type = types.path;
      default = "/.well-known/ways/internal-health-check";
    };

    useConsul = mkOption {
      type = types.bool;
      internal = true;
      default = false;
    };

    nginxUpstreamName = mkOption {
      type = types.str;
      internal = true;
    };

    extras = mkOption {
      description = "Extra configuration to pass to the nginx virtual host submodule.";
      type = types.deferredModule;
      default = {};
    };
  };

  config = lib.mkMerge [
    (lib.mkIf options.consulService.isDefined {
      useConsul = true;
      nginxUpstreamName = "ways_upstream_${builtins.hashString "md5" options.consulService.value}";
      target = "http://${options.nginxUpstreamName.value}";
    })
  ];
}
