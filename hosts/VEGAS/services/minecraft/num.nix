{ config, pkgs, ... }:
{
  reservePortsFor = [ "mc-num" ];
  services.modded-minecraft-servers.instances.num = {
    enable = true;
    rsyncSSHKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL5C7mC5S2gM0K6x0L/jNwAeQYbFSzs16Q73lONUlIkL" # max@TITAN
    ];
    jvmPackage = pkgs.jdk17;
    jvmInitialAllocation = "2G";
    jvmMaxAllocation = "8G";
    serverConfig = {
      server-port = config.ports.mc-num;
      motd = "Welcome to num's minecraft server";
    };
  };
}
