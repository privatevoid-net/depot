{ tools }:
with tools.vhosts;
{
  "fonts-googleapis-com" = proxyGhost "https" "fonts.googleapis.com";
  "fonts-gstatic-com" = proxyGhost "https" "fonts.gstatic.com";
  "cdnjs-cloudflare-com" = proxyGhost "https" "cdnjs.cloudflare.com";
}
