{ config, lib, name, options, ... }:

with lib;

{
  options = {
    internal = mkOption {
      description = "Whether to only make this Way available internally. Will use the internal subdomain.";
      type = types.bool;
      default = false;
    };

    name = mkOption {
      description = "Domain name to use.";
      type = types.str;
      default = let
        basename = "${name}.${config.domainSuffix}";
      in if config.wildcard then "~^(.+)\.${lib.escapeRegex basename}$" else basename;
    };

    dnsRecord = {
      name = mkOption {
        description = "DNS record name for this Way.";
        type = types.str;
        default = if config.wildcard then "^[^_].+\\.${lib.escapeRegex name}" else name;
      };

      value = mkOption {
        description = "DNS record value for this Way.";
        type = types.deferredModule;
        default = {
          consulService = "${name}.${if config.internal then "ways-proxy-internal" else "ways-proxy"}";
          rewrite.type = lib.mkIf config.wildcard "regex";
        };
      };
    };

    grpc = mkOption {
      description = "Whether this endpoint is a gRPC service.";
      type = types.bool;
      default = false;
    };

    target = mkOption {
      type = types.str;
    };

    wildcard = mkOption {
      type = types.bool;
      default = false;
    };

    consulService = mkOption {
      type = types.str;
    };

    bucket = mkOption {
      type = types.str;
    };

    healthCheckPath = mkOption {
      type = types.path;
      default = "/.well-known/ways/internal-health-check";
    };

    url = mkOption {
      type = types.str;
      readOnly = true;
      default = "https://${name}.${config.domainSuffix}";
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

    domainSuffixInternal = mkOption {
      type = types.str;
      internal = true;
    };

    domainSuffixExternal = mkOption {
      type = types.str;
      internal = true;
    };

    domainSuffix = mkOption {
      type = types.str;
      internal = true;
      default = if config.internal then config.domainSuffixInternal else config.domainSuffixExternal;
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
      target = "${if config.grpc then "grpc" else "http"}://${options.nginxUpstreamName.value}";
    })
    (lib.mkIf options.bucket.isDefined {
      consulService = "garage-web";
    })
  ];
}
