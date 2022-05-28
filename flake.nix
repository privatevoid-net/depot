{
  description = "Private Void system configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11-small";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    nix-super.url = "git+https://git.privatevoid.net/max/nix-super-fork";
    nix-super.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "git+https://git.privatevoid.net/max/deploy-rs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    nar-serve.url = "github:numtide/nar-serve/v0.5.0";
    nar-serve.inputs.nixpkgs.follows = "nixpkgs";

    dream2nix.url = "github:nix-community/dream2nix";
    dream2nix.inputs.nixpkgs.follows = "nixpkgs";
    
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    
    mms.url = "github:mkaito/nixos-modded-minecraft-servers";
    mms.inputs.nixpkgs.follows = "nixpkgs";
    
    hercules-ci-agent.url = "github:hercules-ci/hercules-ci-agent";
    hercules-ci-effects.url = "github:hercules-ci/hercules-ci-effects";
  };
  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];

      forSystems = nixpkgs.lib.genAttrs systems;

      nixpkgsFor = system: import nixpkgs {
        inherit system;
      };

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
        modules = [ host.nixos ./tools/inject.nix ];
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

      depot = forSystems (system: import ./packages {
        inherit inputs system;
        pkgs = nixpkgsFor system;
      });

      effects = inputs.hercules-ci-effects.lib.withPkgs (nixpkgsFor "x86_64-linux");
    in {
      nixosModules = aspect.modules;

      nixosConfigurations = lib.genAttrs nixosHosts mkNixOS;

      deploy.nodes = mkDeployments deployableNixosHosts {};

      apps = forSystems (system: {
      });

      packages = forSystems (system: depot.${system}.packages);

      devShells = forSystems (system: depot.${system}.devShells);

      effects = { branch, ... }: mkDeployEffects branch deployableNixosHosts;
    };
}
