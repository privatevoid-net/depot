{
  ssh = {
    enable = true;
    id.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDShq3dbZy9SARsH8aSjfMQ+/eTW44eZuHVCLvgtDNKw";
  };

  interfaces = {
    primary = {
      addr = "10.10.3.2";
      addrPublic = "95.216.8.12";
      link = "eth0";
      prefixLength = 30;
      gatewayAddr = "10.10.3.1";
    };
  };

  enterprise = {
    subdomain = "int";
  };

  system = "x86_64-linux";
  nixos = ./system.nix;
}
