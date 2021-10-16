{
  security.sudo.extraRules = [
    ({
      users = [ "deploy" ];
      commands = [
        "NOPASSWD: /nix/store/*-activate-rs/activate-rs"
        "NOPASSWD: /run/current-system/sw/bin/rm /tmp/deploy-rs-canary-*"
      ];
      runAs = "root";
    })
  ];
  nix.trustedUsers = [ "deploy" ];
  users.users.deploy = {
    isNormalUser = true;
    uid = 1999;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMmdWfmAs/0rno8zJlhBFMY2SumnHbTNdZUXJqxgd9ON max@jericho"
    ];
  };
}
