{ depot, lib, pkgs, ... }:

{
  disabledModules = [
    "hardware/facter/system.nix"
  ];
  
  imports = [
    depot.inputs.nixpkgs.nixosModules.readOnlyPkgs
  ];

  options.nixpkgs.system = lib.mkOption {
    type = lib.types.str;
    default = pkgs.stdenv.hostPlatform.system;
    readOnly = true;
  };

  config.nixpkgs.overlays = lib.mkForce [];
}
