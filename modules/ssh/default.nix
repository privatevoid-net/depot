{ hosts, config, lib, ... }:
let
  filtered = lib.filterAttrs (_: host: host ? ssh) hosts;
  idCapable = lib.filterAttrs (_: host: host.ssh ? id) filtered;
  configCapable = lib.filterAttrs (_: host: host.ssh ? extraConfig) filtered;

  sshHosts = lib.mapAttrs (_: host: host.ssh.id) idCapable;
  sshExtras = lib.mapAttrsToList (_: host: host.ssh.extraConfig) configCapable;
in {
  programs.ssh = {
    knownHosts = sshHosts;
    extraConfig = builtins.concatStringsSep "\n" sshExtras;
  };
}
