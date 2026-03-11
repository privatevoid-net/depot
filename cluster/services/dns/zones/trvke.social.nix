{ config, ... }:

{
  dns.zones."trvke.social".records = {
    inherit (config.dns.records) NS;
  };
}
