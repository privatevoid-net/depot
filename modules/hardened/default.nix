{
  boot.kernel.sysctl = {
    "kernel.yama.ptrace_scope" = 1;
    "kernel.kptr_restrict" = 2;

    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;

    "net.ipv4.conf.all.send_redirects" = false;
    "net.ipv4.conf.default.send_redirects" = false;
  };
}
