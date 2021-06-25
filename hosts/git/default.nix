tools: {
  ssh.id = with tools.dns; {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC0rChVEO9Qt7hr7vyiyOP7N45CjaxssFCZNOPCszEQi";
    hostNames = subResolve "git" "services";
  };
  nixos = import ./system.nix;
}
