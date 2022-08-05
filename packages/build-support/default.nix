{ pkgs, ... }:

{
  imports = [
    ./options.nix
  ];

  builders = {
    fetchAsset = pkgs.callPackage ./fetch-asset { };
  };
}
