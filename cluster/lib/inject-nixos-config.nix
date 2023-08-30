{ config, lib, ... }:
with lib;

{
  options.out.injectNixosConfig = mkOption {
    description = "NixOS configuration to inject into the given host.";
    type = with types; functionTo raw;
    default = const [];
  };
}
