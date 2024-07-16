{ depot, lib, ... }:

{
  imports = [
    depot.inputs.nixpkgs.nixosModules.readOnlyPkgs
  ];

  nixpkgs.overlays = lib.mkForce [];
}
