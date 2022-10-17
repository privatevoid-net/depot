{
  nix.trustedUsers = [ "nix" ];
  users.users.nix = {
    isSystemUser = true;
    description = "Nix Remote Build";
    home = "/var/tmp/nix-remote-builder";
    createHome = true;
    useDefaultShell = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBa9gDXWdp7Kqzbjz9Zchu91ZoYcBD6AbjvuktYA//yg"
    ];
    group = "nix";
  };
  users.groups.nix = {};
}
