tools: {
  ssh.id = with tools.dns; {
    publicKey = "ssh-invalid";
    hostNames = subResolve "meet" "services";
  };
  nixos = import ./system.nix;
}
