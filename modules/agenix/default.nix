{ depot, ... }:

{
  imports = [
    depot.inputs.agenix.nixosModules.age
  ];
}
