{ config, ... }:

{
  dns.zones."zedless.org".records = {
    inherit (config.dns.records) NS;
  };
}
