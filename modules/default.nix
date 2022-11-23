inputs:
with builtins;
let
  aspects = {
    autopatch = import ./autopatch;
    deploy-rs-receiver = import ./deploy-rs-receiver;
    enterprise = import ./enterprise;
    fail2ban = import ./fail2ban;
    hydra = import ./hydra;
    hyprspace = import ./hyprspace;
    ipfs = import ./ipfs;
    ipfs-cluster = import ./ipfs-cluster;
    maintenance = import ./maintenance;
    minimal = import ./minimal;
    motd = import ./motd;
    nix-builder = import ./nix-builder;
    nix-config-server = import ./nix-config/server.nix;
    nix-register-flakes = import ./nix-register-flakes;
    patroni = import ./patroni;
    port-magic = import ./port-magic;
    shell-config = import ./shell-config;
    ssh = import ./ssh;
    sss = import ./sss;
    system-info = import ./system-info;
    system-recovery = import ./system-recovery;
    tested = import ./tested;
  };
in rec {
  modules = aspects;
  sets = with modules; rec {
    base = [
      autopatch
      enterprise
      maintenance
      minimal
    ];

    networking = [
      port-magic
      ssh
    ];

    server = [
      deploy-rs-receiver
      fail2ban
      motd
      nix-config-server
      system-info
      system-recovery
      tested
    ] ++ base ++ networking;

    container = [
      nix-config-server
    ] ++ base ++ networking;

    backbone = server ++ [
      sss
    ];
  };
}
