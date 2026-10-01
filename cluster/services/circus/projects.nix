{ lib, ... }:

let
  toList = lib.mapAttrsToList (name: value: value // { inherit name; });

  flakeProject = {
    url,
    description,
    expressions,
    systems ? null,
  }: {
    inherit description;
    repository_url = url;
    jobsets = lib.mapAttrsToList (name: nix_expression: {
      inherit name nix_expression;
    } // lib.optionalAttrs (systems != null) { inherit systems; }) expressions;
  };
in

{
  services.circus.settings.declarative.projects = toList {
    bunker-patches = flakeProject {
      url = "https://github.com/amaanq/bunker-patches";
      description = "Kernel patches for the Bunker kernel";
      expressions = {
        checks = "checks.x86_64-linux";
      };
    };

    cade = flakeProject {
      url = "https://github.com/manic-systems/cade";
      description = "An intelligent, cascading environment manager";
      expressions = {
        packages = "packages.x86_64-linux";
      };
    };

    circus = flakeProject {
      url = "https://github.com/manic-systems/circus";
      description = "Declarative Nix CI system for clowns";
      expressions = {
        checks = "checks.x86_64-linux";
        packages = "packages.x86_64-linux";
      };
    };

    dix = flakeProject {
      url = "https://github.com/manic-systems/dix";
      description = "A blazingly fast tool to diff Nix related things";
      expressions = {
        packages = "packages.x86_64-linux";
      };
    };

    hyprspace = flakeProject {
      url = "https://github.com/hyprspace/hyprspace";
      description = "Lightweight VPN built on IPFS and libp2p";
      expressions = {
        checks = "checks.x86_64-linux";
        packages = "packages.x86_64-linux";
      };
    };

    inshellah = flakeProject {
      url = "https://github.com/manic-systems/inshellah";
      description = "The last word in Nushell completions";
      expressions = {
        checks = "checks.x86_64-linux";
        packages = "packages.x86_64-linux";
      };
    };

    nixos-core = flakeProject {
      url = "https://github.com/manic-systems/nixos-core";
      description = "Core NixOS utilities in safe, portable Rust";
      expressions = {
        checks = "checks.x86_64-linux";
        packages = "packages.x86_64-linux";
      };
    };

    nixtopsy = flakeProject {
      url = "https://github.com/manic-systems/nixtopsy";
      description = "Interactively dissect your Nix closures";
      expressions = {
        packages = "packages.x86_64-linux";
      };
    };

    npr = flakeProject {
      url = "https://github.com/manic-systems/npr";
      description = "A pull request tracker for Nixpkgs";
      expressions = {
        packages = "packages.x86_64-linux";
      };
    };

    rom = flakeProject {
      url = "https://github.com/manic-systems/rom";
      description = "A flamboyant output monitor for the Nix build tool";
      expressions = {
        packages = "packages.x86_64-linux";
      };
    };

    tack = flakeProject {
      url = "https://github.com/manic-systems/tack";
      description = "Flake-like TOML Nix pins, lazily fetched and transformed";
      expressions = {
        checks = "checks";
        packages = "packages";
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    };

    typst-flake = flakeProject {
      url = "https://github.com/manic-systems/typst-flake";
      description = "Typst builds tracked directly from upstream Git sources";
      expressions = {
        packages = "packages.x86_64-linux";
      };
    };

    xdg-utils-nu = flakeProject {
      url = "https://github.com/manic-systems/xdg-utils.nu";
      description = "Modern and compatible xdg-utils replacement powered by Nushell";
      expressions = {
        packages = "packages.x86_64-linux";
      };
    };
  };
}
