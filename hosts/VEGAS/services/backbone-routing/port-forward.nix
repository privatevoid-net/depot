{
  networking.nat.forwardPorts = [
    {
      sourcePort = 52222;
      destination = "10.10.2.205:22";
      proto = "tcp";
    }
  ];
}
