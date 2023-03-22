{
  security.sudo.extraRules = [
    {
      users = [ "deploy" ];
      commands = [
        "NOPASSWD: /nix/store/*-activate-rs/activate-rs"
        "NOPASSWD: /run/current-system/sw/bin/rm /tmp/deploy-rs-canary-*"
      ];
      runAs = "root";
    }
  ];
  nix.settings.trusted-users = [ "deploy" ];
  users.users.deploy = {
    isNormalUser = true;
    uid = 1999;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMmdWfmAs/0rno8zJlhBFMY2SumnHbTNdZUXJqxgd9ON max@jericho"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL5C7mC5S2gM0K6x0L/jNwAeQYbFSzs16Q73lONUlIkL max@TITAN"
    ];
  };
}
