{
  services.kanidm.unixSettings = {
    pam_allowed_login_groups = [
      "soda"
      "soda-admins"
    ];
  };
}
