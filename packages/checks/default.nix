{ lib, self, ... }:

{
  perSystem = { filters, pkgs, self', ... }: let
    fakeCluster = import ../../cluster {
      inherit lib;
      hostName = throw "not available in test environment";
      depot = throw "not available in test environment";
    };
  in {
    checks = filters.doFilter filters.checks {
      ascensions = pkgs.callPackage ./ascensions.nix {
        inherit (self) nixosModules;
      };

      jellyfin-stateless = pkgs.callPackage ./jellyfin-stateless.nix {
        inherit (self'.packages) jellyfin;
        inherit fakeCluster;
      };

      keycloak = pkgs.callPackage ./keycloak-custom-jre.nix {
        jre = self'.packages.jre17_standard;
      };

      patroni = pkgs.callPackage ./patroni.nix {
        inherit (self) nixosModules;
        inherit (self'.packages) postgresql;
      };
      searxng = pkgs.callPackage ./searxng.nix {
        inherit (self'.packages) searxng;
      };
      tempo = pkgs.callPackage ./tempo.nix {
        inherit (self'.packages) tempo;
      };
    };
  };
}
