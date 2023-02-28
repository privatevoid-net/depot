tools: {
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
  };

  enterprise = {
    subdomain = "node";
  };

  arch = "x86_64";
  nixos = import ./system.nix;
}
