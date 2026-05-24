{ depot, ... }:

{
  imports = [
    depot.inputs.nixos-core.nixosModules.nixos-core
  ];

  system.nixos-core.enable = true;
}