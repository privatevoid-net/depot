{ config, lib, depot, ... }:

{
  services.hercules-ci-multi-agent = {
    nodes = {
      private-void = [ "VEGAS" "prophet" ];
      nixpak = [ "VEGAS" "prophet" ];
      max = [ "VEGAS" "prophet" ];
    };
    nixos = {
      private-void = [
        ./common.nix
        ./orgs/private-void.nix
      ];
      nixpak = [
        ./common.nix
        ./orgs/nixpak.nix
      ];
      max = [
        ./common.nix
        ./orgs/max.nix
      ];
    };
  };
}
