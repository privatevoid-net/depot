{ config, lib, ... }:
{
  incandescence = lib.mkIf config.simulacrum {
    providers = config.lib.forService "incandescence" {
      test.objects.example = [ "example1" "example2" ];
    };
  };
}
