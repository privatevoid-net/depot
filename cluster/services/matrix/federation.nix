{ config, pkgs, depot, ... }:
let
  inherit (depot.lib.meta) domain;
  federation = pkgs.writeText "matrix-federation.json" (builtins.toJSON {
    "m.server" = "matrix.${domain}:443";
  });
in
{
  services.nginx.virtualHosts."top-level.${domain}".locations = {
    "= /.well-known/matrix/server".alias = federation;
    inherit (config.services.nginx.virtualHosts."matrix.${domain}".locations) "= /.well-known/matrix/client";
  };
}
