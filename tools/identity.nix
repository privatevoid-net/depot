# internal interface
{ toolsets }:
# external interface
{ lib ? null, domain ? toolsets.meta.domain, ... }:
let
  tools = (self: {

    inherit domain;

    ldap = {
      server = with self.ldap.server; {
        # TODO: unhardcode everything here
        protocol = "ldaps";
        hostname = "authsys.virtual-machines.${domain}";
        port = 636;
        url = "${protocol}://${connectionString}";
        connectionString = "${hostname}:${builtins.toString port}";
      };
      accounts = with self.ldap.accounts; {
        domainComponents = self.ldap.lib.convertDomain domain;
        uidAttribute = "uid";
        uidFilter = "(${uidAttribute}=%u)";
        userSearchBase = "cn=users,cn=accounts,${domainComponents}";
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
    dns.master.addr = "10.10.0.11";
    kerberos.kdc = "authsys.virtual-machines.${domain}";

  }) tools;
in tools
