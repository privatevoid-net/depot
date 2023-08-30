{ depot, ... }:
with depot.lib.nginx.mappers;
with depot.lib.nginx.vhosts;
{
  services.nginx.virtualHosts = mapSubdomains {
    "bone-ds-dc.com-ldap" = static "/srv/storage/www/bone-meme/dist";
    "rzentrale" = static "/srv/storage/www/rzentrale"; 
    "wunschnachricht" = static "/srv/storage/www/wunschnachricht"; 
  };
}
