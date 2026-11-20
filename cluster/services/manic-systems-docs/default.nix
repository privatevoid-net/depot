{ config, ... }:

{
  garage = config.lib.forService "manic-systems-docs" {
    buckets.docs-manic-systems.web.enable = true;
  };

  ways = config.lib.forService "manic-systems-docs" {
    docs-manic-systems = {
      bucket = "docs-manic-systems";
      name = "docs";
      domainSuffix = "manic.systems";
    };
  };
}
