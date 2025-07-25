{ packages, tools }:
with tools.vhosts;
{
  # websites
  ktp    = static "/srv/storage/www/soda/ktp";
  legacy = static "/srv/storage/www/legacy";
  soda   = static "/srv/storage/www/soda" // {
    extraConfig = ''
      error_page 404 /.nginx-private/404.html;
      error_page 500 502 503 504 /.nginx-private/50x.html;
    '';
  };

  # content delivery
  autoconfig = static "/srv/storage/www/autoconfig";
}
