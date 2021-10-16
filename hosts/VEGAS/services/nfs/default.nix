{ lib, tools, ... }:
{
  imports = [ ./exports.nix ];
  services.nfs = {
    server = {
      enable = true;
    };
    idmapd.settings = {
      General.Domain = lib.mkForce tools.meta.domain;
    };
  };
}
