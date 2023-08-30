{ depot, ... }:
with depot.lib.nginx.vhosts;
let
  inherit (depot.lib.meta) domain;
  front = "ident.${domain}";
  back = depot.lib.identity.ldap.server.hostname;
in
{
  services.nginx.virtualHosts."${front}" = basic // {
    locations."= /".return = "302 /ipa/ui/";
    locations."/" = {
      # HACK: not using proxy_pass here to prevent inclusion of recommended headers
      extraConfig = ''
        proxy_pass https://10.10.0.11;
        proxy_set_header Host ${back};
        proxy_set_header Referer https://${back}/ipa/ui/;
        proxy_cookie_domain ${back} ${front};
        add_header Referer https://${front}/ipa/ui/;
      '';
    };
  };
}

