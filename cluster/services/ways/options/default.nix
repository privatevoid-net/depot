{ lib, depot, ... }:

{
  options.ways = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      imports = [ ./way.nix ];
      domainSuffixExternal = depot.lib.meta.domain;
      domainSuffixInternal = "internal.${depot.lib.meta.domain}";
    });
    default = {};
  };
}
