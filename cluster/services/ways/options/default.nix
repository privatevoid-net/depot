{ config, lib, depot, ... }:

{
  options.ways = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({ options, ... }: {
      imports = [ ./way.nix ];
      domainSuffixExternal = depot.lib.meta.domain;
      domainSuffixInternal = "internal.${depot.lib.meta.domain}";

      extras = lib.mkIf options.bucket.isDefined {
        locations."/".extraConfig = ''
          proxy_set_header Host "${options.bucket.value}.${config.links.garageWeb.hostname}";
        '';
      };
    }));
    default = {};
  };
}
