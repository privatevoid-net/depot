tools: rec {
  ssh.enable = true;
  ssh.id = with tools.dns; {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAUG/ubwo68tt2jMP5ia0Sa4mnkWtlKVN5n4Y50U2nTC";
    hostNames = subResolve "prophet" "node";
  };

  interfaces = {
    primary = {
      addr = "10.0.243.216";
      addrPublic = "152.67.75.145";
      link = "enp0s6";
      prefixLength = 24;
      gatewayAddr = "10.0.243.1";
    };
    vstub = {
      addr = "10.1.0.9";
      link = "vstub";
    };
  };

  hardware = {
    cpu.cores = 4;
    memory.gb = 24;
  };

  hyprspace = {
    enable = true;
    id = "QmbrAHuh4RYcyN9fWePCZMVmQjbaNXtyvrDCWz4VrchbXh";
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
