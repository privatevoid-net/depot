{ lib, ... }:
with lib;

{
  options = {
    system = mkOption {
      description = "Nix system double for this NixOS host.";
      type = types.enum systems.doubles.linux;
      default = "x86_64-linux";
    };

    nixos = mkOption {
      description = "NixOS configuration.";
      type = with types; nullOr anything;
      default = null;
    };
  };
}
