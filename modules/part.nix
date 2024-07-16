{ config, ... }:

let
  group = imports: { inherit imports; };
in

{
  flake.nixosModules = with config.flake.nixosModules; {
    ascensions = ./ascensions;
    consul-distributed-services = ./consul-distributed-services;
    consul-service-registry = ./consul-service-registry;
    effect-receiver = ./effect-receiver;
    enterprise = ./enterprise;
    external-storage = ./external-storage;
    fail2ban = ./fail2ban;
    hyprspace = ./hyprspace;
    ipfs = ./ipfs;
    ipfs-cluster = ./ipfs-cluster;
    maintenance = ./maintenance;
    minimal = ./minimal;
    motd = ./motd;
    networking = ./networking;
    nix-builder = ./nix-builder;
    nix-config-server = ./nix-config/server.nix;
    nixpkgs-config = ./nixpkgs-config;
    nix-register-flakes = ./nix-register-flakes;
    patroni = ./patroni;
    port-magic = ./port-magic;
    reflection = ./reflection;
    shell-config = ./shell-config;
    ssh = ./ssh;
    system-info = ./system-info;
    system-recovery = ./system-recovery;
    systemd-extras = ./systemd-extras;
    tested = ./tested;

    machineBase = group [
      enterprise
      maintenance
      minimal
      nixpkgs-config
      port-magic
      reflection
      ssh
      systemd-extras
    ];

    serverBase = group [
      machineBase
      ascensions
      consul-distributed-services
      consul-service-registry
      effect-receiver
      external-storage
      fail2ban
      motd
      networking
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
