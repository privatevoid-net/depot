tools: {
  ssh.id = with tools.dns; {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOYLrmiuPK77cw71QNzG2zaWs6gsxmYuLyqsUrWMYLnk";
    hostNames = subResolve "styx" "services";
  };
  nixos = import ./system.nix;
}
