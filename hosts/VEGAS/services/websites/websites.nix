{ packages, tools }:
with tools.vhosts;
let inherit (tools) domain; in
{
  # websites
  ktp    = static "/srv/storage/www/soda/ktp";
  legacy = static "/srv/storage/www/legacy";
  soda   = static "/srv/storage/www/soda"; # TODO: add back custom error pages, wttr.in cache

  # content delivery
  autoconfig = static "/srv/storage/www/autoconfig";
}
