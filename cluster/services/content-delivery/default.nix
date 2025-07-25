{ config, ... }:

{
  garage = config.lib.forService "content-delivery" {
    buckets.content-delivery.web.enable = true;
  };

  ways = config.lib.forService "content-delivery" {
    cdn.bucket = "content-delivery";
  };
}
