{ modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
  ];
  fileSystems."/boot" = { device = "/dev/disk/by-partlabel/boot"; fsType = "vfat"; };
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = { device = "/dev/disk/by-partlabel/rootfs"; fsType = "xfs"; };
  swapDevices = [ { device = "/dev/disk/by-partlabel/swap"; } ];
}
