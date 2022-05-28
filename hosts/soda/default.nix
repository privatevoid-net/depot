tools: {
  ssh.id = with tools.dns; {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDShq3dbZy9SARsH8aSjfMQ+/eTW44eZuHVCLvgtDNKw";
    hostNames = subResolve "soda" "int";
  };

  interfaces = {
    primary = {
      addr = "10.10.2.206";
      addrPublic = "95.216.8.12";
      link = "eth0";
    };
  };

  enterprise = {
    subdomain = "int";
  };

  arch = "x86_64";
  nixos = import ./system.nix;
  container = true;
}
