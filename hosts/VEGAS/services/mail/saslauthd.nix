{ pkgs, depot, ... }:
let
  inherit (depot.lib.identity) ldap;
in
{
  services.saslauthd = {
    enable = true;
    mechanism = "ldap";
    package = pkgs.cyrus_sasl.override { enableLdap = true; };
    config = ''
      ldap_servers: ${ldap.server.url}
      ldap_filter: ${ldap.accounts.uidFilter}
      ldap_search_base: ${ldap.accounts.userSearchBase}
      ldapdb_canon_attr: ${ldap.accounts.uidAttribute}
    '';
  };
}
