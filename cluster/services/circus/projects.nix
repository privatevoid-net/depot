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
    bagel = flakeProject {
      url = "https://github.com/manic-systems/bagel";
      description = "HTTP proxy and SSH tarpit daemon that delays malicious scanners";
      expressions = {
        checks = "checks";
        packages = "packages";
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "powerpc64le-linux"
        "loongarch64-linux"
        "powerpc64-linux"
        "riscv64-linux"
      ];
    };

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
        packages = "packages";
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "powerpc64le-linux"
        "loongarch64-linux"
        "powerpc64-linux"
        "riscv64-linux"
      ];
    };

    circus = flakeProject {
      url = "https://github.com/manic-systems/circus";
      description = "Declarative Nix CI system for clowns";
      expressions = {
        checks = "checks.x86_64-linux";
        packages = "packages.x86_64-linux";
      };
    };

    climax = flakeProject {
      url = "https://github.com/manic-systems/climax";
      description = "max your CLI.";
      expressions = {
        devShells = "devShells";
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    };

    custos = flakeProject {
      url = "https://github.com/manic-systems/custos";
      description = "A small and simple USB authorization daemon";
      expressions = {
        packages = "packages";
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };

    dix = flakeProject {
      url = "https://github.com/manic-systems/dix";
      description = "A blazingly fast tool to diff Nix related things";
      expressions = {
        packages = "packages.x86_64-linux";
      };
    };

    evix = flakeProject {
      url = "https://github.com/manic-systems/evix";
      description = "Library-first async Nix evaluation engine for fast cached eval distribution";
      expressions = {
        checks = "checks";
        packages = "packages";
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };

    helium-flake = flakeProject {
      url = "https://github.com/amaanq/helium-flake";
      description = "Nix flake for the Helium browser";
      expressions = {
        checks = "checks";
        packages = "packages";
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };

    hyprspace = flakeProject {
      url = "https://github.com/hyprspace/hyprspace";
      description = "Lightweight VPN built on IPFS and libp2p";
      expressions = {
        checks = "checks.x86_64-linux";
        packages = "packages.x86_64-linux";
      };
    };

    ides = flakeProject {
      url = "https://github.com/manic-systems/ides";
      description = "Idempotent devshell ephemeral services";
      expressions = {
        lucius = ".";
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "powerpc64le-linux"
        "loongarch64-linux"
        "aarch64-darwin"
      ];
    };

    inshellah = flakeProject {
      url = "https://github.com/manic-systems/inshellah";
      description = "The last word in Nushell completions";
      expressions = {
        checks = "checks";
        packages = "packages";
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "powerpc64le-linux"
        "loongarch64-linux"
        "powerpc64-linux"
        "riscv64-linux"
      ];
    };

    jmapper = flakeProject {
      url = "https://github.com/amaanq/jmapper";
      description = "Map IMAP, SMTP, CalDAV, and CardDAV accounts into JMAP";
      expressions = {
        checks = "checks";
        packages = "packages";
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "powerpc64le-linux"
        "loongarch64-linux"
        "powerpc64-linux"
        "riscv64-linux"
      ];
    };

    knead = flakeProject {
      url = "https://github.com/manic-systems/knead";
      description = "A KDL parser and typed decoder";
      expressions = {
        checks = "checks";
        packages = "packages";
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "powerpc64le-linux"
        "loongarch64-linux"
        "powerpc64-linux"
        "riscv64-linux"
      ];
    };

    ncro = flakeProject {
      url = "https://github.com/manic-systems/ncro";
      description = "Lightweight HTTP proxy for optimizing Nix cache routes for fast access";
      expressions = {
        checks = "checks";
        hydraJobs = "hydraJobs";
        packages = "packages";
      };
    };

    nixon = flakeProject {
      url = "https://github.com/manic-systems/nixon";
      description = "Fast and tiny Nix expression parser with C and WASM bindings";
      expressions = {
        checks = "checks";
        packages = "packages";
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };

    nixos-core = flakeProject {
      url = "https://github.com/manic-systems/nixos-core";
      description = "Core NixOS utilities in safe, portable Rust";
      expressions = {
        checks = "checks";
        packages = "packages";
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "powerpc64le-linux"
        "loongarch64-linux"
        "powerpc64-linux"
        "riscv64-linux"
      ];
    };

    nixploit = flakeProject {
      url = "https://github.com/manic-systems/nixploit";
      description = "Nix vulnerability scanning";
      expressions = {
        packages = "packages";
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "powerpc64le-linux"
        "riscv64-linux"
      ];
    };

    nixtopsy = flakeProject {
      url = "https://github.com/manic-systems/nixtopsy";
      description = "Interactively dissect your Nix closures";
      expressions = {
        packages = "packages";
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "powerpc64le-linux"
        "loongarch64-linux"
        "powerpc64-linux"
        "riscv64-linux"
      ];
    };

    npr = flakeProject {
      url = "https://github.com/manic-systems/npr";
      description = "A pull request tracker for Nixpkgs";
      expressions = {
        packages = "packages.x86_64-linux";
      };
    };

    rampart = flakeProject {
      url = "https://github.com/amaanq/rampart";
      description = "Self-hosted forward-only email alias manager";
      expressions = {
        checks = "checks";
        packages = "packages";
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "powerpc64le-linux"
        "loongarch64-linux"
        "powerpc64-linux"
        "riscv64-linux"
      ];
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
        "powerpc64le-linux"
        "loongarch64-linux"
        "powerpc64-linux"
        "riscv64-linux"
      ];
    };

    typst-flake = flakeProject {
      url = "https://github.com/manic-systems/typst-flake";
      description = "Typst builds tracked directly from upstream Git sources";
      expressions = {
        packages = "packages.x86_64-linux";
      };
    };

    vela = flakeProject {
      url = "https://github.com/manic-systems/vela";
      description = "A post-link obfuscator for WebAssembly modules";
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

    watchdog = flakeProject {
      url = "https://github.com/manic-systems/watchdog";
      description = "Lightweight, privacy-first analytics system with fully declarative configuration";
      expressions = {
        packages = "packages";
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
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
