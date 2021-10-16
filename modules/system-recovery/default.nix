{
  users.users = { 
    sa = {
      isNormalUser = true;
      initialHashedPassword = "$6$/WpFHuBXPJHZx$nq0YnOvSTSqu2B3OkPITSPCKUPVfPK04wbPpK/Ntla2MRWJb5eRzKxIK.ASBq0lKay7xpZW0PnQ58qnDTBkf8/";
      hashedPassword = "$6$/WpFHuBXPJHZx$nq0YnOvSTSqu2B3OkPITSPCKUPVfPK04wbPpK/Ntla2MRWJb5eRzKxIK.ASBq0lKay7xpZW0PnQ58qnDTBkf8/";
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ 
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMmdWfmAs/0rno8zJlhBFMY2SumnHbTNdZUXJqxgd9ON max@jericho"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL5C7mC5S2gM0K6x0L/jNwAeQYbFSzs16Q73lONUlIkL max@TITAN"
      ];
    };
    sa_max = {
      isNormalUser = true;
      uid = 2000;
      initialHashedPassword = "$6$/WpFHuBXPJHZx$nq0YnOvSTSqu2B3OkPITSPCKUPVfPK04wbPpK/Ntla2MRWJb5eRzKxIK.ASBq0lKay7xpZW0PnQ58qnDTBkf8/";
      hashedPassword = "$6$/WpFHuBXPJHZx$nq0YnOvSTSqu2B3OkPITSPCKUPVfPK04wbPpK/Ntla2MRWJb5eRzKxIK.ASBq0lKay7xpZW0PnQ58qnDTBkf8/";
      group = "wheel";
      openssh.authorizedKeys.keys = [ 
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMmdWfmAs/0rno8zJlhBFMY2SumnHbTNdZUXJqxgd9ON max@jericho"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL5C7mC5S2gM0K6x0L/jNwAeQYbFSzs16Q73lONUlIkL max@TITAN"
      ];
    };
    sa_alex = {
      isNormalUser = true;
      uid = 2001;
      initialHashedPassword = "$6$/WpFHuBXPJHZx$nq0YnOvSTSqu2B3OkPITSPCKUPVfPK04wbPpK/Ntla2MRWJb5eRzKxIK.ASBq0lKay7xpZW0PnQ58qnDTBkf8/";
      hashedPassword = "$6$/WpFHuBXPJHZx$nq0YnOvSTSqu2B3OkPITSPCKUPVfPK04wbPpK/Ntla2MRWJb5eRzKxIK.ASBq0lKay7xpZW0PnQ58qnDTBkf8/";
      group = "wheel";
      openssh.authorizedKeys.keys = [ 
      ];
    };
  };
}
