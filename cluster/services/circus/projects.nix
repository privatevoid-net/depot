{ lib, ... }:

let
  toList = lib.mapAttrsToList (name: value: value // { inherit name; });

  flakeProject = {
    url,
    expressions,
  }: {
    repository_url = url;
    jobsets = lib.mapAttrsToList (name: nix_expression: {
      inherit name nix_expression;
    }) expressions;
  };
in

{
  services.circus.settings.declarative.projects = toList {
    bunker-patches = flakeProject {
      url = "https://github.com/amaanq/bunker-patches";
      expressions = {
        checks = "checks.x86_64-linux";
      };
    };

    cade = flakeProject {
      url = "https://github.com/manic-systems/cade";
      expressions = {
        packages = "packages.x86_64-linux";
      };
    };

    circus = flakeProject {
      url = "https://github.com/manic-systems/circus";
      expressions = {
        checks = "checks.x86_64-linux";
        packages = "packages.x86_64-linux";
      };
    };

    dix = flakeProject {
      url = "https://github.com/manic-systems/dix";
      expressions = {
        packages = "packages.x86_64-linux";
      };
    };

    headroom = flakeProject {
      url = "https://github.com/manic-systems/headroom";
      expressions = {
        packages = "packages.x86_64-linux";
      };
    };

    hyprspace = flakeProject {
      url = "https://github.com/hyprspace/hyprspace";
      expressions = {
        checks = "checks.x86_64-linux";
        packages = "packages.x86_64-linux";
      };
    };

    inshellah = flakeProject {
      url = "https://github.com/manic-systems/inshellah";
      expressions = {
        checks = "checks.x86_64-linux";
        packages = "packages.x86_64-linux";
      };
    };

    nixos-core = flakeProject {
      url = "https://github.com/manic-systems/nixos-core";
      expressions = {
        checks = "checks.x86_64-linux";
        packages = "packages.x86_64-linux";
      };
    };

    nixtopsy = flakeProject {
      url = "https://github.com/manic-systems/nixtopsy";
      expressions = {
        packages = "packages.x86_64-linux";
      };
    };

    npr = flakeProject {
      url = "https://github.com/manic-systems/npr";
      expressions = {
        packages = "packages.x86_64-linux";
      };
    };

    rom = flakeProject {
      url = "https://github.com/manic-systems/rom";
      expressions = {
        packages = "packages.x86_64-linux";
      };
    };

    tack = flakeProject {
      url = "https://github.com/manic-systems/tack";
      expressions = {
        checks = "checks.x86_64-linux";
        packages = "packages.x86_64-linux";
      };
    };

    typst-flake = flakeProject {
      url = "https://github.com/manic-systems/typst-flake";
      expressions = {
        packages = "packages.x86_64-linux";
      };
    };

    xdg-utils-nu = flakeProject {
      url = "https://github.com/manic-systems/xdg-utils.nu";
      expressions = {
        packages = "packages.x86_64-linux";
      };
    };
  };
}
