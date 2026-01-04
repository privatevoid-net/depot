tools: rec {
  ssh = {
    enable = true;
    id.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICz2nGA+Y4OxhMKsV6vKIns3hOoBkK557712h7FfWXcE";
  };

  interfaces = {
    primary = {
      addr = "95.216.8.12";
      link = "enp0s31f6";
      prefixLength = 26;
      gatewayAddr = "95.216.8.1";
    };
    vstub = {
      addr = "10.1.0.1";
      link = "vstub";
    };
  };

  hardware = {
    cpu.cores = 8;
    memory.gb = 64;
  };

  hyprspace = {
    enable = true;
    id = "QmYs4xNBby2fTs8RnzfXEk161KD4mftBfCiR8yXtgGPj4J";
    listenPort = 995;
    routes = [
      "${interfaces.vstub.addr}/32"
      "10.10.0.0/16"
    ];
  };

  enterprise = {
    subdomain = "backbone";
  };

  system = "x86_64-linux";
  nixos = ./system.nix;
}
