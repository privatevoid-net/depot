{ tools }:
with tools.vhosts;
{
  "fonts-googleapis-com" = proxyGhost "https" "fonts.googleapis.com";
  "fonts-gstatic-com" = proxyGhost "https" "fonts.gstatic.com";
  "cdnjs-cloudflare-com" = proxyGhost "https" "cdnjs.cloudflare.com";
  "bidhhjb5tfchhhgx-lambda" = proxyGhost "https" "bidhhjb5tfchhhgxatvudfvxma0nfujn.lambda-url.eu-central-1.on.aws";
  "wttr-in" = let
    proxy = proxyGhost "https" "wttr.in";
  in proxy // {
    locations."/".extraConfig = proxy.locations."/".extraConfig + ''
      proxy_cache wttr;
      proxy_cache_key $uri;
      proxy_cache_min_uses 1;
      proxy_cache_methods GET HEAD POST;
      proxy_cache_valid any 10m;
      proxy_cache_bypass $cookie_nocache $arg_nocache$arg_comment;
      proxy_cache_lock on;
      proxy_cache_use_stale updating;
    '';
  };
}
