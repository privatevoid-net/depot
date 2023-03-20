tools: {
  ssh.enable = true;
  ssh.id = with tools.dns; {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGV8TbMvGXfAp9R2I9GdR7aLlGjxh2CW1pCZjQSB4TJp";
    hostNames = subResolve "thunderskin" "node";
  };

  interfaces = {
    primary = {
      addr = "10.0.243.121";
      addrPublic = "140.238.208.154";
      link = "ens3";
    };
  };

  hyprspace = {
    enable = true;
    id = "12D3KooWB9AUPorFoACkWbphyargRBV9osJsYuQDumtQ85j7Aqmg";
    addr = "10.100.3.4";
    listenPort = 995;
  };

  enterprise = {
    subdomain = "node";
  };

  system = "x86_64-linux";
  nixos = ./system.nix;
}
