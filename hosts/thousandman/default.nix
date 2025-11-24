tools: rec {
  ssh.enable = true;
  ssh.id = with tools.dns; {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMC/1nLPJMYaEE4p9NGK8CJBt+HNUc7tR2WT4maBlrmh";
    hostNames = subResolve "thousandman" "node";
  };

  interfaces = {
    primary = {
      addr = "159.195.33.251";
      link = "ens3";
    };
    vstub = {
      addr = "10.1.0.100";
      link = "vstub";
    };
  };

  hardware = {
    cpu.cores = 8;
    memory.gb = 16;
  };

  hyprspace = {
    enable = false;
    listenPort = 995;
    routes = [
      "${interfaces.vstub.addr}/32"
    ];
  };

  system = "x86_64-linux";
  nixos = ./system.nix;
}
