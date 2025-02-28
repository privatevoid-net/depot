{ depot, lib, pkgs, ... }:
let
  inherit (depot.lib.nginx) domain vhosts;
  inherit (depot.packages) cinny;
in
{
  services.nginx.virtualHosts."chat.${domain}" = lib.recursiveUpdate
  (vhosts.static cinny.webroot)
  {
    locations."=/config.json".alias = pkgs.writeText "cinny-config.json" (builtins.toJSON {
      defaultHomeserver = 0;
      homeserverList = [ "${domain}" ];
      allowCustomHomeservers = false;
    });
    locations."/".extraConfig = ''
      rewrite ^/config.json$ /config.json break;
      rewrite ^/manifest.json$ /manifest.json break;

      rewrite ^.*/olm.wasm$ /olm.wasm break;
      rewrite ^/pdf.worker.min.js$ /pdf.worker.min.js break;

      rewrite ^/public/(.*)$ /public/$1 break;
      rewrite ^/assets/(.*)$ /assets/$1 break;

      rewrite ^(.+)$ /index.html break;
    '';
  };

  security.acme.certs."chat.${domain}" = {
    dnsProvider = "exec";
    webroot = lib.mkForce null;
  };
}
