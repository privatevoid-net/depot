{ lib, pkgs, ... }:

{
  services.homed.enable = true;

  systemd.services.activate-lvm-homedirs = {
    wantedBy = [ "systemd-homed.service" ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      ${pkgs.lvm2.bin}/bin/lvs --noheadings -o lv_name --select 'pool_lv = "home"' \
        | tr -d ' ' \
        | ${pkgs.findutils}/bin/xargs -I HOMEDIR_VOLUME_NAME ${pkgs.multipath-tools}/bin/kpartx -a /dev/mapper/shelf-HOMEDIR_VOLUME_NAME
    '';
  };

  security.pam.services.login.enableGnomeKeyring = lib.mkForce false;

  services.udev.extraRules = ''
    SUBSYSTEM=="block", ENV{ID_PART_ENTRY_TYPE}=="773f91ef-66d4-49b5-bd83-d683bf40ad16", ENV{UDISKS_IGNORE}="1"
  '';
}
