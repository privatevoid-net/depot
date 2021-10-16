{ tools }:
with tools.vhosts;
let inherit (tools) domain; in
{
  # websites
  ktp    = static "/srv/storage/www/soda/ktp";
  legacy = static "/srv/storage/www/legacy";
  soda   = static "/srv/storage/www/soda"; # TODO: add back custom error pages, wttr.in cache
  www    = simplePHP "/srv/storage/www/${domain}" // { default = true; };

  "shadertool.dev" = proxy "http://test-generic.int.${domain}";
  "kokaido" = proxy "http://test-generic.int.${domain}:8080";

  # content delivery
  autoconfig = static "/srv/storage/www/autoconfig";
  rpm = static "/srv/storage/rpm";

  "whoami".locations = { # no tls
    "/".return = ''200 "$remote_addr\n"'';
    "/online".return = ''200 "CONNECTED_GLOBAL\n"'';
  };

  top-level = redirect "https://www.${domain}$request_uri" // { serverName = domain; };
}
