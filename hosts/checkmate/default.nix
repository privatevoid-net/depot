tools: rec {
  ssh.enable = true;
  ssh.id = with tools.dns; {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINImnMfEzUBU5qiuu05DMPrddTGypOtr+cL1/yQN2GFn";
    hostNames = subResolve "checkmate" "node";
  };

  interfaces = {
    primary = {
      addr = "10.0.243.198";
      addrPublic = "152.67.73.164";
      link = "ens3";
    };
    vstub = {
      addr = "10.1.0.32";
      link = "vstub";
    };
  };

  hyprspace = {
    enable = true;
    id = "12D3KooWL84sAtq1QTYwb7gVbhSNX5ZUfVt4kgYKz8pdif1zpGUh";
    listenPort = 995;
    routes = [
      "${interfaces.vstub.addr}/32"
    ];
  };

  enterprise = {
    subdomain = "node";
  };

  system = "x86_64-linux";
  nixos = ./system.nix;
}
