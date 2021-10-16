{ lib, tools, ... }:
let
  inherit (tools.meta) domain;
in
{
  services.opendkim = {
    enable = true;
    selector = domain;
    domains = domain;
  };
  # ensure socket becomes group-writable
  systemd.services.opendkim.serviceConfig.UMask = lib.mkForce "0007";
  # TODO: figure out which one works
  users.users.postfix.extraGroups = [ "opendkim" ];
}
