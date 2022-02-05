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
    nix-builder = import ./nix-builder;
    nix-config = import ./nix-config;
    nix-config-server = import ./nix-config/server.nix;
    nix-register-flakes = import ./nix-register-flakes;
    port-magic = import ./port-magic;
    shell-config = import ./shell-config;
    ssh = import ./ssh;
    sss = import ./sss;
    system-recovery = import ./system-recovery;
  };
in rec {
  modules = aspects;
  sets = with modules; rec {
    base = [ 
      autopatch
      enterprise
    ];

    networking = [
      port-magic
      ssh
    ];

    server = [
      deploy-rs-receiver
      nix-config-server
      system-recovery
    ] ++ base ++ networking;

    backbone = server ++ [
      fail2ban
      sss
    ];
  };
}
