inputs: 
with builtins;
let
  aspects = {
    autopatch = import ./autopatch;
    deploy-rs-receiver = import ./deploy-rs-receiver;
    enterprise = import ./enterprise;
    hydra = import ./hydra;
    ipfs-lain = import ./ipfs-lain;
    nix-builder = import ./nix-builder;
    nix-config = import ./nix-config;
    nix-config-server = import ./nix-config/server.nix;
    nix-register-flakes = import ./nix-register-flakes;
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

    networking = [ ssh ];

    server = [
      deploy-rs-receiver
      nix-config-server
      system-recovery
    ] ++ base ++ networking;
  };
}
