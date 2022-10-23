{
  description = "Private Void system configurations";
  nixConfig = {
    allow-import-from-derivation = true;
    extra-substituters = "https://cache.privatevoid.net";
    extra-trusted-public-keys = "cache.privatevoid.net:SErQ8bvNWANeAvtsOESUwVYr2VJynfuc9JRwlzTTkVg=";
  };

  outputs = { self, nixpkgs, flake-parts, ... }@inputs:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];

      nixpkgsFor = nixpkgs.legacyPackages;

      inherit (nixpkgs) lib;

      aspect = import ./modules inputs;
      hosts = import ./hosts;

      nixosHosts' = lib.filterAttrs (_: host: host ? nixos) hosts;

      nixosHosts = lib.attrNames nixosHosts';

      deployableNixosHosts' = lib.filterAttrs (_: host: host ? container -> !host.container) nixosHosts';

      deployableNixosHosts = lib.attrNames deployableNixosHosts';

      meta = import ./tools/meta.nix;

      specialArgs = {
        inherit inputs hosts aspect;
        toolsets = import ./tools;
      };
      mkNixOS' = lib: name: let host = hosts.${name}; in lib.nixosSystem {
        inherit specialArgs;
        system = "${host.arch}-linux";
        modules = [ host.nixos ./tools/inject.nix (import ./cluster/inject.nix name) ];
      };
      mkNixOS = mkNixOS' lib;  

      mkDeployEffect = branch: name: host: let
        subdomain = host.enterprise.subdomain or "services";
        hostname = "${lib.toLower name}.${subdomain}.${meta.domain}";
      in effects.runIf (branch == "master" || branch == "staging") (effects.runNixOS {
        requiredSystemFeatures = [ "hci-deploy-agent-nixos" ];
        inherit (self.nixosConfigurations.${name}) config;
        secretsMap.ssh = "deploy-ssh";

        userSetupScript = ''
          writeSSHKey ssh
          cat >>~/.ssh/known_hosts <<EOF
          ${hostname} ${host.ssh.id.publicKey}
          EOF
        '';
        ssh.destination = "root@${hostname}";
      });

      mkDeployEffects = branch: hostnames: lib.genAttrs hostnames
        (name: mkDeployEffect branch name hosts.${name});

      mkDeploy = name: let
        host = hosts.${name};
        subdomain = host.enterprise.subdomain or "services";
        deploy-rs = inputs.deploy-rs.lib."${host.arch}-linux";
      in {
        hostname = "${lib.toLower name}.${subdomain}.${meta.domain}";
        profiles.system = {
          user = "root";
          sshUser = "deploy";
          path = deploy-rs.activate.nixos self.nixosConfigurations.${name};
        };
      };

      mkDeployments = hosts: overrides: lib.genAttrs hosts
        (host: mkDeploy host // (overrides.${host} or {}) );

      effects = inputs.hercules-ci-effects.lib.withPkgs nixpkgsFor.x86_64-linux;
    in flake-parts.lib.mkFlake { inherit self; } {
      inherit systems;
      flake = {
        nixosModules = aspect.modules;

        nixosConfigurations = lib.genAttrs nixosHosts mkNixOS;

        deploy.nodes = mkDeployments deployableNixosHosts {};

        effects = { branch, ... }: mkDeployEffects branch deployableNixosHosts;
      };
      imports = [
        ./packages/part.nix
      ];
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05-small";
    nixpkgs-lib.url = "github:NixOS/nixpkgs/nixos-22.05-small?dir=lib";

    nix-super = {
      url = "gitlab:max/nix-super?host=git.privatevoid.net";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-regression.follows = "blank";
      };
    };

    deploy-rs = {
      url = "gitlab:max/deploy-rs?host=git.privatevoid.net";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "blank";
        utils.follows = "repin-flake-utils";
      };
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nar-serve = {
      url = "github:numtide/nar-serve/v0.5.0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "repin-flake-utils";
      };
    };

    dream2nix = {
      url = "github:nix-community/dream2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        alejandra.follows = "blank";
        all-cabal-json.follows = "blank";
        crane.follows = "blank";
        devshell.follows = "blank";
        flake-utils-pre-commit.follows = "blank";
        ghc-utils.follows = "blank";
        gomod2nix.follows = "blank";
        mach-nix.follows = "blank";
        poetry2nix.follows = "poetry2nix";
        pre-commit-hooks.follows = "blank";
      };
    };
    
    devshell = {
      url = "github:numtide/devshell";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "repin-flake-utils";
      };
    };
    
    mms = {
      url = "github:mkaito/nixos-modded-minecraft-servers";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix.follows = "nix-super";
        flake-compat.follows = "blank";
        flake-utils.follows = "repin-flake-utils";
      };
    };
    
    hercules-ci-agent = {
      url = "github:hercules-ci/hercules-ci-agent";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        nix-darwin.follows = "blank";
      };
    };
    hercules-ci-effects = {
      url = "github:hercules-ci/hercules-ci-effects";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    };

    nix-filter.url = "github:numtide/nix-filter";
    
    repin-flake-utils.url = "github:numtide/flake-utils";

    blank.url = "github:divnix/blank";

    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "repin-flake-utils";
      };
    };

    nixos-command = {
      url = "github:max-privatevoid/nixos-command";
      inputs = {
        flake-utils.follows = "repin-flake-utils";
        nixpkgs.follows = "nixpkgs";
        poetry2nix.follows = "poetry2nix";
      };
    };
  };
}
