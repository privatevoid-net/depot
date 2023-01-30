{ pkgs, inputs', self', ... }:

{
  drv-parts.dependencySets = {
    inherit pkgs inputs' self';
    inherit (pkgs) python3Packages;
  };
}
