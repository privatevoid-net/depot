{ depot, lib, ... }:
let
  filtered = lib.filterAttrs (_: host: host.ssh.enable) depot.hours;
  idCapable = lib.filterAttrs (_: host: host.ssh.id.publicKey != null) filtered;
  configCapable = lib.filterAttrs (_: host: host.ssh.extraConfig != "") filtered;
  sshExtras = lib.mapAttrsToList (_: host: host.ssh.extraConfig) configCapable;
in {
  programs.ssh = {
    knownHosts = lib.mapAttrs (name: host: let
      baseName = lib.toLower name;
    in {
      inherit (host.ssh.id) publicKey;
      hostNames = [
        baseName
        "${baseName}.${host.enterprise.subdomain}.${depot.lib.meta.domain}"
      ];
    }) idCapable;
    extraConfig = builtins.concatStringsSep "\n" sshExtras;
  };
}
