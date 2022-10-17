{ lib, ... }:
with lib;

{
  options.out.injectedNixosConfig = mkOption {
    description = "NixOS configuration modules to inject into the host.";
    type = with types; listOf anything;
    default = {};
  };
}
