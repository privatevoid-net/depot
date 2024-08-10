{ lib, ... }:

{
  lib = { config, ... }: with config.nginx; {
    nginx = {
      inherit (config.meta) domain;

      mappers = {

        mapSubdomains = with lib; mapAttrs' (k: nameValuePair "${k}.${domain}");

      };

      vhosts = with vhosts; {

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

        proxyGhost = scheme: target: basic // {
          locations."/".extraConfig = ''
            set $nix_proxy_ghost_target "${scheme}://${target}";
            proxy_pass $nix_proxy_ghost_target;
            proxy_set_header Host ${target};
            proxy_set_header Referer ${scheme}://${target};
            proxy_cookie_domain ${target} domain.invalid;
            proxy_set_header Cookie "";
          '';
        };
      };
    };
  };
}

