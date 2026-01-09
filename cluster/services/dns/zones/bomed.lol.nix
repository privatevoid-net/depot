{ config, ... }:

{
  dns.zones."bomed.lol".records = {
    inherit (config.dns.records) NS;
  };
}
