{ depot, ... }:

{
  networking.nat.forwardPorts = [
    {
      sourcePort = 52222;
      destination = "${depot.hours.soda.interfaces.primary.addr}:22";
      proto = "tcp";
    }
  ];
}
