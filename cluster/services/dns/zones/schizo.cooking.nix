# @ 3600 IN MX 0 mx.privatevoid.net.

{ config, ... }:

{
  dns.zones."schizo.cooking".records = {
    inherit (config.dns.records) NS;
  };
}
