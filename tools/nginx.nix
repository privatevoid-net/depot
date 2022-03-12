# internal interface
{ toolsets }:
# external interface
{ config ? null, lib ? null, domain ? toolsets.meta.domain, ... }:
let
  tools = (self: {

    inherit domain;

    mappers = {

      mapSubdomains = with lib; mapAttrs' (k: nameValuePair "${k}.${domain}");

    };

    vhosts = with self.vhosts; {

      basic = {
        forceSSL = true;
        enableACME = true;
      };

      redirect = target: basic // {
        locations."/".return = "301 ${target}";
      };

      proxy = target: basic // {
        locations."/".proxyPass = target;
      };

      static = root: basic // {
        inherit root;
      };

      indexedStatic = root: (static root) // {
        extraConfig = "autoindex on;";
      };

      simplePHP = root: (static root) // {
        locations."~ \.php$".extraConfig = ''
          fastcgi_pass  unix:${config.services.phpfpm.pools.www.socket};
          fastcgi_index index.php;
        '';
      };

      proxyGhost = scheme: target: basic // {
        locations."/".extraConfig = ''
          proxy_pass ${scheme}://${target};
          proxy_set_header Host ${target};
          proxy_set_header Referer ${scheme}://${target};
          proxy_cookie_domain ${target} domain.invalid;
          proxy_set_header Cookie "";
        '';
      };

    };
  }) tools;
in tools
