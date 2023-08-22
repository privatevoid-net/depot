{ config, ... }:

let
  group = imports: { inherit imports; };
in

{
  flake.nixosModules = with config.flake.nixosModules; {
    autopatch = ./autopatch;
    consul-service-registry = ./consul-service-registry;
    deploy-rs-receiver = ./deploy-rs-receiver;
    effect-receiver = ./effect-receiver;
    enterprise = ./enterprise;
    external-storage = ./external-storage;
    fail2ban = ./fail2ban;
    hydra = ./hydra;
    hyprspace = ./hyprspace;
    ipfs = ./ipfs;
    ipfs-cluster = ./ipfs-cluster;
    maintenance = ./maintenance;
    minimal = ./minimal;
    motd = ./motd;
    nix-builder = ./nix-builder;
    nix-config-server = ./nix-config/server.nix;
    nix-register-flakes = ./nix-register-flakes;
    patroni = ./patroni;
    port-magic = ./port-magic;
    shell-config = ./shell-config;
    ssh = ./ssh;
    system-info = ./system-info;
    system-recovery = ./system-recovery;
    tested = ./tested;

    machineBase = group [
      autopatch
      enterprise
      maintenance
      minimal
      port-magic
      ssh
    ];

    serverBase = group [
      machineBase
      consul-service-registry
      deploy-rs-receiver
      effect-receiver
      external-storage
      fail2ban
      motd
      nix-config-server
      system-info
      system-recovery
      tested
    ];

    containerBase = group [
      machineBase
      nix-config-server
    ];

    backboneBase = group [
      serverBase
    ];
  };
}
