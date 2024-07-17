{ config, lib, ... }:

{
  systemd.tmpfiles.settings."00-testing-external-storage-underlays" = lib.mapAttrs' (name: cfg: {
    name = cfg.mountpoint;
    value.d = {
      user = toString cfg.uid;
      group = toString cfg.gid;
      mode = "0700";
    };
  }) config.services.external-storage.underlays;
}
