{
  virtualisation.libvirtd.enable = true;
  # TODO: maybe be more strict
  networking.firewall.trustedInterfaces = [
    "vmcore"
    "vmdefault"
  ];
}
