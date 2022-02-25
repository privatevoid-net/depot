{ pkgs, inputs, ... }:
let
  inherit (pkgs) system;
  dream2nix = inputs.dream2nix.lib.init {
    systems = [ system ];
    config.overridesDirs = [ ./dream2nix-overrides ];
  };
  poetry2nix = pkgs.poetry2nix.overrideScope' (final: prev: {
    defaultPoetryOverrides = prev.defaultPoetryOverrides.extend (import ./poetry2nix-overrides);
  });
in
{
  ghost = (dream2nix.riseAndShine {
    source = ./servers/ghost/dream-lock.json;
    sourceOverrides = oldSources: let
      version = "4.32.3";
    in {

      # building ghost ourselves is a pain in the ass, so just use the zip
      "ghost"."${version}" = pkgs.fetchzip {
        url = "https://github.com/TryGhost/Ghost/releases/download/v${version}/Ghost-${version}.zip";
        sha256 = "sha256-XneO6es3eeJz4v1JnWtUfm27zwUW2Wy3hTIHUF7UrFc=";
        stripRoot = false;
      };
    };
  }).defaultPackage.${system};

  hyprspace = pkgs.callPackage ./networking/hyprspace { iproute2mac = null; };

  minio-console = pkgs.callPackage ./servers/minio-console { };

  privatevoid-smart-card-ca-bundle = pkgs.callPackage ./data/privatevoid-smart-card-certificate-authority-bundle.nix { };
  
  reflex-cache = poetry2nix.mkPoetryApplication {
    projectDir = ./servers/reflex-cache;
    meta.mainProgram = "reflex";
  };

  sips = pkgs.callPackage ./servers/sips { };
}
