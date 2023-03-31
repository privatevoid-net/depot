{ pkgs, inputs', self', ... }:

{
  drv-parts.packageSets = {
    inherit pkgs inputs' self';
    inherit (pkgs) python3Packages;
  };
}
