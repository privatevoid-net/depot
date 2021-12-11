{
  description = "Private Void system configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";

    nix-super.url = "git+https://git.privatevoid.net/max/nix-super";
    nix-super.inputs.nix.follows = "nix-super-unstable-repin";

    nix-super-unstable-repin.url = "github:NixOS/nix";
    nix-super-unstable-repin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "git+https://git.privatevoid.net/max/deploy-rs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    nar-serve.url = "github:numtide/nar-serve/v0.5.0";
    nar-serve.inputs.nixpkgs.follows = "nixpkgs";
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
      specialArgs = {
        inherit inputs hosts aspect;
        toolsets = import ./tools;
      };
      mkNixOS' = lib: name: lib.nixosSystem {
        inherit system;
        inherit specialArgs;
        modules = [ hosts."${name}".nixos ./tools/inject.nix ];
      };
      mkNixOS = mkNixOS' lib;  
    in {
      nixosModules = aspect.modules;
      nixosConfigurations = lib.genAttrs [
        "styx"
        "meet" 
        "git"
        "VEGAS"
      ] mkNixOS;

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
        VEGAS = {
          hostname = "vegas.backbone.privatevoid.net";
          profiles.system = {
            user = "root";
            sshUser = "deploy";
            path = activate.nixos self.nixosConfigurations.VEGAS;
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
