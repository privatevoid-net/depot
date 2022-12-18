{ pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    qemu.package = pkgs.qemu_kvm;
  };
  security.polkit.enable = true;
  # TODO: maybe be more strict
  networking.firewall.trustedInterfaces = [
    "vmcore"
    "vmdefault"
  ];
}
