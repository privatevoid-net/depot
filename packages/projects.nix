{ pkgs, inputs, system, ... }@args:
let
  inherit (pkgs) lib;
  inherit (inputs) unstable;

  pins = import ./sources;

  dream2nix = inputs.dream2nix.lib2.init {
    inherit pkgs;
    config = {
      projectRoot = ./.;
      overridesDirs = [ ./dream2nix-overrides ];
    };
  };
  poetry2nix = pkgs.poetry2nix.overrideScope' (final: prev: {
    defaultPoetryOverrides = prev.defaultPoetryOverrides.extend (import ./poetry2nix-overrides);
  });
  
  mkShell = import lib/devshell.nix args;

in
{
  packages = rec {
    ghost = let
      version = "4.41.3";
      dream = dream2nix.makeOutputs {
        source = pkgs.fetchzip {
          url = "https://github.com/TryGhost/Ghost/releases/download/v${version}/Ghost-${version}.zip";
          sha256 = "sha256-mqN43LSkd9MHoIHyGS1VsPvpqWqX4Bx5KHcp3KOHw5A=";
          stripRoot = false;
        };
      };
      inherit (dream.packages) ghost;
    in
      ghost;

    uptime-kuma = let
      dream = dream2nix.makeOutputs {
        source = pins.uptime-kuma;
      };
      inherit (dream.packages) uptime-kuma;
    in
      uptime-kuma;

    grafana = pkgs.callPackage ./monitoring/grafana { };

    hyprspace = pkgs.callPackage ./networking/hyprspace { iproute2mac = null; };

    ipfs = pkgs.callPackage ./networking/ipfs { };

    npins = let
      inherit (inputs.self.packages.${system}) nix-super;
    in pkgs.callPackage ./tools/npins {
      nix = nix-super;
      nix-prefetch-git = pkgs.nix-prefetch-git.override {
        nix = nix-super;
      };
    };

    privatevoid-smart-card-ca-bundle = pkgs.callPackage ./data/privatevoid-smart-card-certificate-authority-bundle.nix { };

    reflex-cache = poetry2nix.mkPoetryApplication {
      projectDir = ./servers/reflex-cache;
      meta.mainProgram = "reflex";
    };

    searxng = pkgs.callPackage ./web-apps/searxng { inherit pins; };

    sips = pkgs.callPackage ./servers/sips { };

    stevenblack-hosts = pkgs.callPackage ./data/stevenblack { inherit pins; };
  };

  checks = import ./tests { inherit inputs pkgs system; };

  devShells = {
    default = let
      flakePkgs = inputs.self.packages.${system};
    in mkShell {
      tools = with flakePkgs; [
        agenix
        deploy-rs
        npins
      ];

      env.NPINS_DIRECTORY.eval = "$REPO_ROOT/packages/sources";
    };
    reflex-cache = let
      inherit (inputs.self.packages.${system}) reflex-cache;
    in mkShell {
      packages = [
        reflex-cache.dependencyEnv
      ];
      
      tools = [
        pkgs.poetry
      ];

      env.PYTHON = reflex-cache.dependencyEnv.interpreter;
    };
  };
}
