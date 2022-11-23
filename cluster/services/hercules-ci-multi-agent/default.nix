{ config, lib, tools, ... }:

{
  services.hercules-ci-multi-agent = {
    nodes = {
      private-void = [ "VEGAS" "prophet" ];
      nixpak = [ "VEGAS" ];
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
    };
  };
}
