tools: rec {
  ssh.enable = true;
  ssh.id = with tools.dns; {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBi5Fm2pmMBhRgJms+me1ldt9Vgj9cMSnB7UllSz3mpY";
    hostNames = subResolve "grail" "node";
  };

  interfaces = {
    primary = {
      addr = "37.27.11.202";
      link = "enp1s0";
    };
    vstub = {
      addr = "10.1.0.6";
      link = "vstub";
    };
  };

  hardware = {
    cpu.cores = 4;
    memory.gb = 8;
  };

  hyprspace = {
    enable = true;
    id = "12D3KooWN31twBvdEcxz2jTv4tBfPe3mkNueBwDJFCN4xn7ZwFbi";
    listenPort = 995;
    routes = [
      "${interfaces.vstub.addr}/32"
    ];
  };

  enterprise = {
    subdomain = "node";
  };

  system = "aarch64-linux";
  nixos = ./system.nix;
}
