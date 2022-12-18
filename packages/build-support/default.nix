{ pkgs, ... }:

{
  imports = [
    ./options.nix

    ./drv-parts
  ];

  builders = rec {
    fetchAsset = pkgs.callPackage ./fetch-asset { };

    hydrateAssetDirectory = pkgs.callPackage ./hydrate-asset-directory {
      inherit fetchAsset;
    };
  };
}
