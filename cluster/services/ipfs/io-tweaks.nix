{
  systemd.services.ipfs = {
    serviceConfig = {
      LimitNOFILE = 524288;
      IOSchedulingPriority = 7;
    };
  };

  systemd.slices.remotefshost.sliceConfig = {
    IOWeight = 5;
    IOReadIOPSMax = [ 
      "/dev/sda 100"
      "/dev/sdb 100"
    ];
    IOWriteIOPSMax = [ 
      "/dev/sda 100"
      "/dev/sdb 100"
    ];
    IODeviceLatencyTargetSec = [ 
      "/dev/sda 500ms"
      "/dev/sdb 500ms"
    ];
  };
}
