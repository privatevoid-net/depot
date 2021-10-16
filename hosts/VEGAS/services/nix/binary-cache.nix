{ config, tools, ... }:
with tools.nginx;
let
  addrSplit' = builtins.split ":" config.services.minio.listenAddress;
  addrSplit = builtins.filter builtins.isString addrSplit';
  host' = builtins.head addrSplit;
  host = if host' == "" then "127.0.0.1" else host';
  port = builtins.head (builtins.tail addrSplit);
in
{
  services.nginx.virtualHosts."cache.${tools.meta.domain}" = vhosts.basic // {
    locations = {
      "= /".return = "302 /404";
      "/".proxyPass = "http://${host}:${port}/nix-store$request_uri";
      "/nix/store".proxyPass = "http://127.0.0.1:${builtins.toString config.services.nar-serve.port}";
    };
  };
}
