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
        inputs.clan.flakeModules.clan
        ./nixpkgs/part.nix
        ./hosts/part.nix
        ./modules/part.nix
        ./packages/part.nix
        ./jobs/part.nix
        ./lib/part.nix
        ./cluster/part.nix
        ./catalog/part.nix
        ./clan/part.nix
      ];
    };

  inputs = {
    systems.url = "github:privatevoid-net/nix-systems-default-linux";

    nixpkgs-input.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixpkgs = {
      url = "https://forge.privatevoid.net/privatevoid.net/customize-nixpkgs/archive/master.tar.gz";
      inputs = {
        nixpkgs.follows = "nixpkgs-input";
        config.follows = "/";
      };
    };

    clan = {
      url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
      inputs = {
        flake-parts.follows = "flake-parts";
        nix-darwin.follows = "blank";
        nixpkgs.follows = "nixpkgs-input";
        systems.follows = "systems";
      };
    };

    nixos-core = {
      url = "github:manic-systems/nixos-core";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-super = {
      url = "https://forge.privatevoid.net/max/nix-super/archive/master.tar.gz";
      inputs = {
        nixpkgs-regression.follows = "blank";
        nixpkgs-23-11.follows = "blank";
      };
    };

    nixpak = {
      url = "github:nixpak/nixpak";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        hercules-ci-effects.follows = "hercules-ci-effects";
      };
    };

    nix-crx = {
      url = "https://forge.privatevoid.net/max/nix-crx/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
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

    ncro = {
      url = "github:manic-systems/ncro";
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

    cade = {
      url = "github:manic-systems/cade";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
        fenix.inputs.rust-analyzer-src.follows = "blank";
      };
    };

    circus = {
      url = "github:manic-systems/circus";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pre-commit.follows = "blank";
      };
    };

    zedless = {
      url = "github:zedless-editor/zedless";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    blank.url = "github:divnix/blank";
  };
}
