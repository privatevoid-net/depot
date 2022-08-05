{ pkgs, ... }:

{
  imports = [
    ./options.nix
  ];

  builders = rec {
    fetchAsset = pkgs.callPackage ./fetch-asset { };

    hydrateAssetDirectory = pkgs.callPackage ./hydrate-asset-directory {
      inherit fetchAsset;
    };
  };
}
