{ config, inputs, pkgs, ... }:
let
  custId = "0fyy6ksf";
in
{
  links."mc-${custId}" = {};
  links."mc-rcon-${custId}" = {};
  services.modded-minecraft-servers.instances."${custId}" = {
    enable = true;
    rsyncSSHKeys = [
      "ssh-ed25519 dummyKey"
    ];
    jvmPackage = inputs.self.packages.${pkgs.system}.jre17_standard;
    jvmInitialAllocation = "2G";
    jvmMaxAllocation = "4G";
    serverConfig = {
      server-port = config.links."mc-${custId}".port;
      motd = "Hosted by Private Void";
      enable-rcon = true;
      rcon-port = config.links."mc-rcon-${custId}".port;
      rcon-password = "manager";
      allow-flight = true;
    };
  };
  systemd.services."mc-${custId}".serviceConfig = {
    CPUQuota = "200%";
    MemoryHigh = "4.2G";
    MemoryMax = "4.3G";
    MemorySwapMax = "1G";
  };
}
