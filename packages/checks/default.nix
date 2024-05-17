{ config, lib, self, ... }:

{
  perSystem = { filters, pkgs, self', system, ... }: {
    checks = lib.mkIf (system == "x86_64-linux") {
      ascensions = pkgs.callPackage ./ascensions.nix {
        inherit (self) nixosModules;
      };

      garage = pkgs.callPackage ./garage.nix {
        inherit (self'.packages) garage;
        inherit (self) nixosModules;
        inherit (config) cluster;
      };

      jellyfin-stateless = pkgs.callPackage ./jellyfin-stateless.nix {
        inherit (self'.packages) jellyfin;
        inherit (config) cluster;
      };

      keycloak = pkgs.callPackage ./keycloak-custom-jre.nix {
        inherit (self'.packages) keycloak;
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
