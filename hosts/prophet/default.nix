tools: {
  ssh.enable = true;
  ssh.id = with tools.dns; {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJZ4FyGi69MksEn+UJZ87vw1APqiZmPNlEYIr0CbEoGv";
    hostNames = subResolve "prophet" "node";
  };

  interfaces = {
    primary = {
      addr = "10.0.0.92";
      addrPublic = "152.67.79.222";
      link = "enp0s3";
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
