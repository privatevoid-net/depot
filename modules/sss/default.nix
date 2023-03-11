{ config, lib, depot, tools, utils, ... }:
let
  inherit (tools.meta) domain;
  inherit (tools) identity;
  inherit (config.networking) hostName;
  inherit (depot.reflection) enterprise interfaces;

  toINI = content: lib.generators.toINI {} (iniFilter content);

  # apply some extra transformations for INI generation
  # 2 layers deep because the attrset for the INI generator does it
  iniFilter = builtins.mapAttrs iniFilter';
  iniFilter' = k: builtins.mapAttrs iniFilter'';
  iniFilter'' = k: v:
    if builtins.isList v then builtins.concatStringsSep ", " v
    else if builtins.isBool v then (if v then "True" else "False")
    else v;

  ipaProvide = services: lib.genAttrs (map (x: "${x}_provider") services) (_: "ipa");

  defaultShell = utils.toShellPath config.users.defaultUserShell;
in
{
  security.pam.services = lib.genAttrs [ "login" "sshd" ] (_: {
    makeHomeDir = true;
    sssdStrictAccess = true;
  });

  services.sssd.enable = true;
  services.sssd.sshAuthorizedKeysIntegration = true;
  services.sssd.config = toINI {
    "domain/${domain}" = {
      dns_discovery_domain = domain;
      ipa_domain = domain;
      ipa_server = [ "_srv_" identity.ldap.server.hostname ];
      ipa_hostname = "${lib.toLower hostName}.${enterprise.subdomain}.${domain}";
    
      # TODO: replace with proper cert
      ldap_tls_cacert = "${../../data/ca.crt}";

      cache_credentials = true;
      krb5_store_password_if_offline = true;

      dyndns_update = interfaces ? primary.link && ! interfaces.primary ? addrPublic;
      dyndns_iface = interfaces.primary.link or "";

      fallback_homedir = "/home/%u@%d";
      default_shell = defaultShell;
      shell_fallback = defaultShell;

      use_fully_qualified_names = false;
    } // ipaProvide [
      "access"
      "auth"
      "autofs"
      "chpass"
      "hostid"
      "id"
      "session"
      "subdomains"
      "sudo"
    ];

    sssd = {
      domains = domain;
      services = [ "nss" "pam" "ssh" "sudo" "autofs" ];
    };
    nss.homedir_substring = "/home";
    pam.pam_cert_auth = true;
  };
}
