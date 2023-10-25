{ lib, ... }:

{
  lib = { config, ... }: with config.identity; {
    identity = {

      inherit (config.meta) domain;

      autoDomain = name: "${builtins.hashString "md5" name}.dev.${domain}";

      ldap = {
        server = with ldap.server; {
          # TODO: unhardcode everything here
          protocol = "ldaps";
          hostname = "idm-ldap.internal.${domain}";
          port = 636;
          url = "${protocol}://${connectionString}";
          connectionString = "${hostname}:${builtins.toString port}";
        };
        accounts = with ldap.accounts; {
          domainComponents = ldap.lib.convertDomain domain;
          uidAttribute = "name";
          uidFilter = "(${uidAttribute}=%u)";
          userSearchBase = "${domainComponents}";
        };
        lib = {
          convertDomain = domain: with builtins; lib.pipe domain [
            (split "\\.")
            (filter isString)
            (map (x: "dc=${x}"))
            (concatStringsSep ",")
          ];
        };
      };
    };
  };
}
