{ pkgs, config, inputs, ... }:
let
  orgDomain = "privatevoid.net";
  orgRealm = "PRIVATEVOID.NET";
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
        kdc = "authsys.virtual-machines.privatevoid.net";
        admin_server = kdc;
        kpasswd_server = kdc;
        default_domain = orgDomain;
      };
    };
  };
  services.pcscd.enable = true;
}
