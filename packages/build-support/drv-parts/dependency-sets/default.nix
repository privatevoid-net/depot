{ pkgs, inputs', self', ... }:

{
  dependencySets = {
    inherit pkgs inputs' self';
    inherit (pkgs) python3Packages;
  };
}
