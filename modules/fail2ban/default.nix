{
  services.fail2ban = {
    enable = true;
    jails.sshd = ''
      enabled = true
      port = 22
      mode = aggressive
    '';
  };
}
