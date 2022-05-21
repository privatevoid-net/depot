{ tools }:
with tools.vhosts;
let
  inherit (tools) domain;

  noSSL = { enableACME = false; forceSSL = false; };
in
{
  "ky.rip" = simplePHP "/srv/storage/www/ky.rip" // noSSL;
}
