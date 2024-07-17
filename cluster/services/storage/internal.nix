{ ... }:

let
  storageDir = "/srv/storage";
in

{
  systemd.tmpfiles.settings."00-storage" = {
    "${storageDir}".d.mode = "0755";
    "${storageDir}/private".d.mode = "0751";
  };
}
