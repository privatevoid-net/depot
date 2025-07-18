{
  description = "Private Void system configurations";
  nixConfig = {
    #allow-import-from-derivation = true;
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
        ./hosts/part.nix
        ./modules/part.nix
        ./packages/part.nix
        ./jobs/part.nix
        ./lib/part.nix
        ./cluster/part.nix
        ./catalog/part.nix
      ];
    };

  inputs = {
    systems.url = "github:privatevoid-net/nix-systems-default-linux";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    nix-super = {
      url = "https://forge.privatevoid.net/max/nix-super/archive/master.tar.gz";
      inputs = {
        nixpkgs-regression.follows = "blank";
        nixpkgs-23-11.follows = "blank";
      };
    };

    hyprspace = {
      url = "github:hyprspace/hyprspace";
      inputs = {
        flake-parts.follows = "flake-parts";
      };
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nar-serve = {
      url = "github:numtide/nar-serve";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    devshell = {
      url = "github:numtide/devshell";
      inputs = {
        nixpkgs.follows = "nixpkgs";
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
      };
    };
    hercules-ci-effects = {
      url = "github:hercules-ci/hercules-ci-effects";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
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
