{ config, inputs, pkgs, ... }:
{
  links.mc-num = {};
  services.modded-minecraft-servers.instances.num = {
    enable = true;
    rsyncSSHKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL5C7mC5S2gM0K6x0L/jNwAeQYbFSzs16Q73lONUlIkL" # max@TITAN
    ];
    jvmPackage = inputs.self.packages.${pkgs.system}.jre17_standard;
    jvmInitialAllocation = "2G";
    jvmMaxAllocation = "8G";
    serverConfig = {
      server-port = config.links.mc-num.port;
      motd = "Welcome to num's minecraft server";
    };
  };
}
