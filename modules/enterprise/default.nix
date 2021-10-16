{ config, pkgs, hosts, inputs, lib, tools, ... }:
let
  orgDomain = tools.meta.domain;
  orgRealm = lib.toUpper orgDomain;
  host = hosts.${config.networking.hostName} or null;
in {
  krb5 = {
    enable = true;
    domain_realm = {
      ${orgDomain} = orgRealm;
      ".${orgDomain}" = orgRealm;
    };
    libdefaults = {
      default_realm = orgRealm;
      dns_lookup_kdc = true;
      rdns = false;
      forwardable = true;
      default_ccache_name = "KEYRING:persistent:%{uid}";
      pkinit_anchors = "FILE:${inputs.self.packages.x86_64-linux.privatevoid-smart-card-ca-bundle}";
    };
    realms = {
      "${orgRealm}" = rec {
        inherit (tools.identity.kerberos) kdc;
        admin_server = kdc;
        kpasswd_server = kdc;
        default_domain = orgDomain;
      };
    };
  };
  services.pcscd.enable = true;
  networking.domain = lib.mkDefault "${host.enterprise.subdomain or "services"}.${orgDomain}";
  networking.search = [ config.networking.domain "search.${orgDomain}" ];
}
