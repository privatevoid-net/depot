{ inputs, lib, pkgs, tools, ... }:
let
  inherit (tools.nginx) domain vhosts;
  inherit (inputs.self.packages.${pkgs.system}) cinny;
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
}
