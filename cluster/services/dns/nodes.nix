{ depot, lib, ... }:

{
  dns.records = lib.mapAttrs' (name: hour: {
    name = lib.toLower "${name}.${hour.enterprise.subdomain}";
    value = {
      type = "A";
      target = [ hour.interfaces.primary.addrPublic ];
    };
  }) depot.gods.fromLight;
}
