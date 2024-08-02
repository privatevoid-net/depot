{ config, lib, self, ... }:

let
  timeMachine = {
    preUnstable = config.lib.timeTravel "637f048ee36d5052e2e7938bf9039e418accde66";
  };
in

{
  debug = lib.warn "debug mode is enabled" true;
  perSystem = { filters, pkgs, self', system, ... }: {
    checks = lib.mkIf (system == "x86_64-linux") {
      ascensions = pkgs.callPackage ./ascensions.nix {
        inherit (self'.packages) consul;
        inherit (self) nixosModules;
        inherit (config) cluster;
      };

      ipfs-cluster-upgrade = pkgs.callPackage ./ipfs-cluster-upgrade.nix {
        inherit (self) nixosModules;
        previous = timeMachine.preUnstable;
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

      s3ql-upgrade = pkgs.callPackage ./s3ql-upgrade.nix {
        inherit (self'.packages) s3ql;
        inherit (self) nixosModules;
        previous = timeMachine.preUnstable;
      };

      searxng = pkgs.callPackage ./searxng.nix {
        inherit (self'.packages) searxng;
      };
    };
  };
}
