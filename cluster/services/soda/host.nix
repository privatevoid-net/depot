{ cluster, config, depot, ... }:

{
  links = {
    quickieInternal.protocol = "http";
    quickie.protocol = "http";
  };

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

  systemd = {
    services = {
      "container@soda".after = [ "libvirtd.service" "sys-devices-virtual-net-vmdefault.device" ];

      quickie = {
        serviceConfig = {
          ExecStart = "${depot.packages.quickie}/bin/quickie -b ${config.links.quickieInternal.ipv4} -p ${config.links.quickieInternal.portStr} -m /tmp/resources -o /tmp -c /resources/asylum-v1.css";
          WorkingDirectory = "/tmp";

          CPUQuota = "10%";
          CapabilityBoundingSet = "";
          DevicePolicy = "closed";
          DynamicUser = true;
          IPAddressAllow = "${config.links.quickieInternal.ipv4}/32";
          IPAddressDeny = "any";
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          MemoryMax = "16M";
          MemorySwapMax = "32M";
          NoNewPrivileges = true;
          PrivateDevices = true;
          PrivateNetwork = true;
          PrivateTmp = true;
          ProcSubset = "pid";
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          RestrictAddressFamilies = "AF_INET";
          RestrictNamespaces = true;
          RestrictRealtime = true;
          SocketBindAllow = "ipv4:tcp:${config.links.quickieInternal.portStr}";
          SocketBindDeny = "any";
          SystemCallArchitectures = "native";
          SystemCallFilter = [ "@system-service" "~@privileged" "~@resources" ];
          TasksMax = 1;
          UMask = "0077";

          InaccessiblePaths = [
            "/boot"
            "/nix/var"
            "/srv"
            "/var"
          ];
          BindReadOnlyPaths = [ "/srv/storage/www/schizo.cooking:/tmp/resources" ];
        };
      };

      quickie-proxy = {
        bindsTo = [ "quickie.service" ];
        after = [ "quickie.service" ];
        unitConfig.JoinsNamespaceOf = "quickie.service";
        serviceConfig = {
          ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd ${config.links.quickieInternal.tuple}";
          DynamicUser = true;
          IPAddressAllow = "${config.links.quickieInternal.ipv4}/32";
          IPAddressDeny = "any";
          MemoryMax = "64M";
          MemorySwapMax = "128M";
          NoNewPrivileges = true;
          PrivateDevices = true;
          PrivateNetwork = true;
          PrivateTmp = true;
          TasksMax = 16;
        };
      };
    };

    sockets.quickie-proxy = {
      wantedBy = [ "sockets.target" ];
      socketConfig.ListenStream = "${cluster.config.hostLinks.${config.networking.hostName}.quickie.tuple}";
    };
  };

  networking.nat.forwardPorts = [
    {
      sourcePort = 52222;
      destination = "${depot.hours.soda.interfaces.primary.addr}:22";
      proto = "tcp";
    }
  ];
}
