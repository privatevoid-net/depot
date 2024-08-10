{ config, lib, ... }:
{
  ways = lib.mkIf config.simulacrum {
    ways-test-simple = config.lib.forService "ways" {
      target = "http://nowhere";
    };
    ways-test-consul = config.lib.forService "ways" {
      consulService = "ways-test-service";
    };
  };
}
