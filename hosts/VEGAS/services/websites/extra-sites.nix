{ tools, ... }:
with tools.vhosts;
let
  noSSL = { enableACME = false; forceSSL = false; };
in
{
  "ky.rip" = simplePHP "/srv/storage/www/ky.rip" // noSSL;
}
