{ pkgs, inputs, system, ... }@args:
let
  inherit (pkgs) lib;
  inherit (inputs) unstable;
  dream2nix = inputs.dream2nix.lib2.init {
    systems = [ system ];
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
      dream = dream2nix.makeFlakeOutputs {
        source = pkgs.fetchzip {
          url = "https://github.com/TryGhost/Ghost/releases/download/v${version}/Ghost-${version}.zip";
          sha256 = "sha256-mqN43LSkd9MHoIHyGS1VsPvpqWqX4Bx5KHcp3KOHw5A=";
          stripRoot = false;
        };
      };
      inherit (dream.packages.${system}) ghost;
    in
      ghost;

    uptime-kuma = let
      dream = dream2nix.makeFlakeOutputs {
        source = builtins.fetchTree {
          type = "github";
          owner = "louislam";
          repo = "uptime-kuma";
          rev = "751924b3355ca44d24ceede1cfdd983383426f5f"; # 1.15.0
        };
      };
      inherit (dream.packages.${system}) uptime-kuma;
    in
      uptime-kuma;

    hyprspace = pkgs.callPackage ./networking/hyprspace { iproute2mac = null; };

    minio-console = pkgs.callPackage ./servers/minio-console { };

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

    searxng = let
      scope = pkgs.python3Packages.overrideScope (final: prev: let
        pullDownPackages = pypkgs: lib.genAttrs pypkgs (pkgName:
          final.callPackage  "${unstable}/pkgs/development/python-modules/${pkgName}/default.nix" {}
        );
      in pullDownPackages [ "httpcore" "httpx" "httpx-socks" "h2" "python-socks" "socksio" ]);
    in pkgs.callPackage ./web-apps/searxng rec {
      python3Packages = scope;
    };

    sips = pkgs.callPackage ./servers/sips { };
  };

  devShells = {
    default = let
      flakePkgs = inputs.self.packages.${system};
    in mkShell {
      tools = with flakePkgs; [
        agenix
        deploy-rs
      ];
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
