{ cluster, depot, ... }:
let
  inherit (depot.lib.meta) domain;
  inherit (cluster.config.services.mail) secrets;
in
{
  services.rspamd = {
    enable = true;
    postfix.enable = true;
    locals = {
      "dkim_signing.conf".text = ''
        enabled = true;

        domain {
          ${domain} {
            selector = "${domain}";
            path = "${secrets.dkimKey.path}";
          }
        }

        sign_authenticated = true;
        sign_local = true;
        sign_inbound = false;

        use_esld = true;
        check_pubkey = true;
        allow_username_mismatch = true;
        auth_only = true;
      '';
    };
  };
}
