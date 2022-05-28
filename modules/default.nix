inputs:
with builtins;
let
  aspects = {
    autopatch = import ./autopatch;
    deploy-rs-receiver = import ./deploy-rs-receiver;
    enterprise = import ./enterprise;
    fail2ban = import ./fail2ban;
    hercules-ci-agent = import ./hercules-ci-agent;
    hydra = import ./hydra;
    hyprspace = import ./hyprspace;
    ipfs = import ./ipfs;
    maintenance = import ./maintenance;
    minimal = import ./minimal;
    monitoring = import ./monitoring;
    motd = import ./motd;
    nix-builder = import ./nix-builder;
    nix-config-server = import ./nix-config/server.nix;
    nix-register-flakes = import ./nix-register-flakes;
    port-magic = import ./port-magic;
    shell-config = import ./shell-config;
    ssh = import ./ssh;
    sss = import ./sss;
    system-info = import ./system-info;
    system-recovery = import ./system-recovery;
  };
in rec {
  modules = aspects;
  sets = with modules; rec {
    base = [
      autopatch
      enterprise
      maintenance
      minimal
      system-info
    ];

    networking = [
      port-magic
      ssh
    ];

    server = [
      deploy-rs-receiver
      fail2ban
      monitoring
      motd
      nix-config-server
      system-recovery
    ] ++ base ++ networking;

    container = [
      nix-config-server
    ] ++ base ++ networking;

    backbone = server ++ [
      sss
    ];
  };
}
