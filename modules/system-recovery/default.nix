{
  users.users = { 
    sa = {
      isNormalUser = true;
      hashedPassword = "$6$/WpFHuBXPJHZx$nq0YnOvSTSqu2B3OkPITSPCKUPVfPK04wbPpK/Ntla2MRWJb5eRzKxIK.ASBq0lKay7xpZW0PnQ58qnDTBkf8/";
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ 
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMmdWfmAs/0rno8zJlhBFMY2SumnHbTNdZUXJqxgd9ON max@jericho"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL5C7mC5S2gM0K6x0L/jNwAeQYbFSzs16Q73lONUlIkL max@TITAN"
        "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBDHyIQ7AWXUKlmNCFDCsl9u/k0cTd9PCXLdx3/oQJ9oLMfwor2HCP6f+Pi5JuEx7D5Guzn1pj7hq8eQh0cpB418AAAAEc3NoOg== max@jericho"
        "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBEV+hYUnt5DnPGuZUsFXi8+YHYPsTxR/Rm96AA9ny8TxauBrLiZfErQgkXfQc3UcVXc/6sBL8AdzMw0Fqs8ISokAAAAEc3NoOg== max@TITAN"
      ];
    };
    sa_max = {
      isNormalUser = true;
      uid = 2000;
      hashedPassword = "$6$/WpFHuBXPJHZx$nq0YnOvSTSqu2B3OkPITSPCKUPVfPK04wbPpK/Ntla2MRWJb5eRzKxIK.ASBq0lKay7xpZW0PnQ58qnDTBkf8/";
      group = "wheel";
      openssh.authorizedKeys.keys = [ 
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMmdWfmAs/0rno8zJlhBFMY2SumnHbTNdZUXJqxgd9ON max@jericho"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL5C7mC5S2gM0K6x0L/jNwAeQYbFSzs16Q73lONUlIkL max@TITAN"
        "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBDHyIQ7AWXUKlmNCFDCsl9u/k0cTd9PCXLdx3/oQJ9oLMfwor2HCP6f+Pi5JuEx7D5Guzn1pj7hq8eQh0cpB418AAAAEc3NoOg== max@jericho"
        "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBEV+hYUnt5DnPGuZUsFXi8+YHYPsTxR/Rm96AA9ny8TxauBrLiZfErQgkXfQc3UcVXc/6sBL8AdzMw0Fqs8ISokAAAAEc3NoOg== max@TITAN"
      ];
    };
  };
}
