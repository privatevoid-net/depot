{
  description = "Private Void system configurations";
  nixConfig = {
    allow-import-from-derivation = true;
    extra-substituters = "https://cache.privatevoid.net";
    extra-trusted-public-keys = "cache.privatevoid.net:SErQ8bvNWANeAvtsOESUwVYr2VJynfuc9JRwlzTTkVg=";
  };

  outputs = { self, nixpkgs, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];
      herculesCI.ciSystems = [ "x86_64-linux" "aarch64-linux" ];

      imports = [
        inputs.hercules-ci-effects.flakeModule
        inputs.drv-parts.modules.flake-parts.drv-parts
        inputs.dream2nix.flakeModuleBeta
        ./hosts/part.nix
        ./modules/part.nix
        ./packages/part.nix
        ./jobs/part.nix
      ];
    };

  inputs = {
    systems.url = "github:privatevoid-net/nix-systems-default-linux";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05-small";

    nix-super = {
      url = "gitlab:max/nix-super?host=git.privatevoid.net";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-regression.follows = "blank";
      };
    };

    deploy-rs = {
      url = "gitlab:max/deploy-rs?host=git.privatevoid.net";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "blank";
        utils.follows = "repin-flake-utils";
      };
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nar-serve = {
      url = "github:numtide/nar-serve/v0.5.0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "repin-flake-utils";
      };
    };

    dream2nix = {
      url = "github:nix-community/dream2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgsV1.follows = "nixpkgs";
        all-cabal-json.follows = "blank";
        crane.follows = "blank";
        devshell.follows = "blank";
        drv-parts.follows = "drv-parts";
        flake-utils-pre-commit.follows = "blank";
        flake-parts.follows = "flake-parts";
        ghc-utils.follows = "blank";
        gomod2nix.follows = "blank";
        mach-nix.follows = "blank";
        nix-pypi-fetcher.follows = "blank";
        pre-commit-hooks.follows = "blank";
        pruned-racket-catalog.follows = "blank";
      };
    };
    
    devshell = {
      url = "github:numtide/devshell";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    
    mms = {
      url = "github:mkaito/nixos-modded-minecraft-servers";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix.follows = "nix-super";
        flake-compat.follows = "blank";
        flake-utils.follows = "repin-flake-utils";
      };
    };
    
    hercules-ci-agent = {
      url = "github:hercules-ci/hercules-ci-agent";
      inputs = {
        flake-parts.follows = "flake-parts";
        nix-darwin.follows = "blank";
      };
    };
    hercules-ci-effects = {
      url = "github:hercules-ci/hercules-ci-effects";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        hercules-ci-agent.follows = "hercules-ci-agent";
      };
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    nix-filter.url = "github:numtide/nix-filter";
    
    repin-flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    blank.url = "github:divnix/blank";

    drv-parts = {
      url = "github:DavHau/drv-parts";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };
}
