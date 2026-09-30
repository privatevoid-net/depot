{ config, ... }:

{
  dns.zones = config.lib.forService "nvd" {
    "manic.systems".records = {
      advisories.target = [
        "152.53.83.122"
      ];
      advisories-v6 = {
        name = "advisories";
        type = "AAAA";
        target = [
          "2a0a:4cc0:2000:3f59::1"
        ];
      };
    };
  };
}
