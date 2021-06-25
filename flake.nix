{
  description = "Private Void system configurations";

  nixConfig = {
    substituters = [ "https://cache.privatevoid.net" ]; 
    trusted-public-keys = ["cache.privatevoid.net:SErQ8bvNWANeAvtsOESUwVYr2VJynfuc9JRwlzTTkVg="];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";

    nix-super-unstable.url = "github:NixOS/nix";
    nix-super-unstable.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.inputs.naersk.follows = "naersk";

    # re-pin naersk to fix deprecation warning in deploy-rs
    naersk.url = "github:nmattia/naersk/master";
    naersk.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      inherit (nixpkgs) lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };

      deploy-rs-lib = inputs.deploy-rs.lib.${system};
      agenixModule = inputs.agenix.nixosModules.age;

      aspect = import ./modules inputs;
      hosts = import ./hosts;
      specialArgs = { inherit inputs hosts aspect; };
      mkNixOS' = lib: name: lib.nixosSystem {
        inherit system;
        inherit specialArgs;
        modules = [ hosts."${name}".nixos ];
      };
      mkNixOS = mkNixOS' lib;  
    in {
      nixosModules = aspect.modules;
      nixosConfigurations = 
      (lib.genAttrs [ "styx" "meet" "git" ] mkNixOS);

      deploy.nodes = with deploy-rs-lib; {
        styx = {
          hostname = "styx.services.privatevoid.net";
          profiles.system = {
            user = "root";
            path = activate.nixos self.nixosConfigurations.styx;
          };
        };
        meet = {
          hostname = "meet.services.privatevoid.net";
          profiles.system = {
            user = "root";
            path = activate.nixos self.nixosConfigurations.meet;
          };
        };
        git = {
          hostname = "git.services.privatevoid.net";
          profiles.system = {
            user = "root";
            path = activate.nixos self.nixosConfigurations.git;
          };
        };
      };

      packages.${system} = import ./packages {
        inherit pkgs inputs;
      };

      defaultApp.${system} = {
        type = "app";
        program = self.packages.${system}.flake-installer.outPath;
      };

      hydraJobs = {
        systems.${system} = lib.mapAttrs (_: x: x.config.system.build.toplevel) self.nixosConfigurations;
        packages = self.packages;
      };
    };
}
