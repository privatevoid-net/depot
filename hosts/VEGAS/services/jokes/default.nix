{ config, lib, tools, ... }:
with tools.nginx.mappers;
with tools.nginx.vhosts;
{
  services.nginx.virtualHosts = mapSubdomains {
    "bone-ds-dc.com-ldap" = static "/srv/storage/www/bone-meme/dist";
    "get" = simplePHP "/srv/storage/www/dietldb";
    "rzentrale" = static "/srv/storage/www/rzentrale"; 
    "wunschnachricht" = static "/srv/storage/www/wunschnachricht"; 
  };
}
