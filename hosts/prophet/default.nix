tools: {
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
    };
  };

  hyprspace = {
    enable = true;
    id = "QmbrAHuh4RYcyN9fWePCZMVmQjbaNXtyvrDCWz4VrchbXh";
    addr = "10.100.3.9";
    listenPort = 995;
  };

  enterprise = {
    subdomain = "node";
  };

  system = "aarch64-linux";
  nixos = ./system.nix;
}
