{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_blk" ];
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/boot" = { device = "/dev/disk/by-partlabel/boot"; fsType = "ext4"; };
  fileSystems."/" = { device = "/dev/disk/by-partlabel/rootfs"; fsType = "ext4"; };
}
