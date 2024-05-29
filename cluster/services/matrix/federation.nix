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
    "= /.well-known/matrix/client".return = "302 https://matrix.${domain}/.well-known/matrix/client";
  };
}
