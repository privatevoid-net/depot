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
  };

  security.acme.certs."chat.${domain}" = {
    dnsProvider = "exec";
    webroot = lib.mkForce null;
  };
}
