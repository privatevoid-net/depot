{ depot, ... }:

{
  imports = [
    depot.inputs.cade.nixosModules.default
  ];

  programs.cade = {
    enable = true;
    direnvCompat = true;
  };
}
