{
  services.kanidm.unix.settings.kanidm = {
    pam_allowed_login_groups = [
      "soda"
      "soda-admins"
    ];
  };
}
