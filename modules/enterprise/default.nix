{ config, depot, lib, tools, ... }:
let
  orgDomain = tools.meta.domain;
  host = depot.reflection;
in {
  networking.domain = lib.mkDefault "${host.enterprise.subdomain or "services"}.${orgDomain}";
  networking.search = [ config.networking.domain "search.${orgDomain}" ];
  security.pki.certificates = [ (builtins.readFile ../../data/ca.crt) ];
}
