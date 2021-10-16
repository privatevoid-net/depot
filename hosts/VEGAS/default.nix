tools: {
  ssh.id = with tools.dns; {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICz2nGA+Y4OxhMKsV6vKIns3hOoBkK557712h7FfWXcE";
    hostNames = subResolve "vegas" "backbone";
  };

  interfaces = {
    primary = {
      addr = "95.216.8.12";
      link = "enp0s31f6";
    };
    vstub = {
      addr = "10.1.0.1";
      link = "vstub";
    };
  };


  enterprise = {
    subdomain = "backbone";
  };

  nixos = import ./system.nix;
}
