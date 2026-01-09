{ config, ... }:

{
  dns.zones."schizo.cooking".records = {
    inherit (config.dns.records) NS;
  };
}
