{ hosts, ... }:

{
  networking.nat.forwardPorts = [
    {
      sourcePort = 52222;
      destination = "${hosts.soda.interfaces.primary.addr}:22";
      proto = "tcp";
    }
  ];
}
