{ depot, ... }:

{
  containers.soda = {
    path = depot.nixosConfigurations.soda.config.system.build.toplevel;
    privateNetwork = true;
    hostBridge = "vmdefault";
    localAddress = "${depot.hours.soda.interfaces.primary.addr}/24";
    autoStart = true;
    bindMounts = {
      sodaDir = {
        hostPath = "/srv/storage/www/soda";
        mountPoint = "/soda";
        isReadOnly = false;
      };
      schizoDir = {
        hostPath = "/srv/storage/www/schizo.cooking";
        mountPoint = "/schizo";
        isReadOnly = false;
      };
    };
  };

  systemd.services."container@soda".after = [ "libvirtd.service" "sys-devices-virtual-net-vmdefault.device" ];

  networking.nat.forwardPorts = [
    {
      sourcePort = 52222;
      destination = "${depot.hours.soda.interfaces.primary.addr}:22";
      proto = "tcp";
    }
  ];
}
