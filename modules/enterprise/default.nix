{ config, depot, lib, ... }:
let
  orgDomain = depot.lib.meta.domain;
  host = config.reflection;
in {
  networking.domain = lib.mkDefault "${host.enterprise.subdomain or "services"}.${orgDomain}";
  networking.search = [ config.networking.domain "search.${orgDomain}" ];
}
