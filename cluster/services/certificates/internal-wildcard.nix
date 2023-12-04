{ config, lib, pkgs, depot, ... }:

let
  inherit (depot.lib.meta) domain;

  extraGroups = [ "nginx" ]
    ++ lib.optional config.services.kanidm.enableServer "kanidm";
in

{
  security.acme.certs."internal.${domain}" = {
    domain = "*.internal.${domain}";
    extraDomainNames = [ "*.internal.${domain}" ];
    dnsProvider = "exec";
    group = "nginx";
    postRun = ''
      ${pkgs.acl}/bin/setfacl -Rb out/
      ${lib.concatStringsSep "\n" (
        map (group: "${pkgs.acl}/bin/setfacl -Rm g:${group}:rX out/") extraGroups
      )}
    '';
  };
}
