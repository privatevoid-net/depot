{ config, ... }:

{
  dns.zones."manic.systems".records = {
    inherit (config.dns.records) NS;
  };
}
