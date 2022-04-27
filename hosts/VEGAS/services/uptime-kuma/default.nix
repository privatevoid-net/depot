{ config, inputs, lib, pkgs, tools, ... }:

let
  inherit (tools.meta) domain;

  flakePkgs = inputs.self.packages.${pkgs.system};

  port = config.portsStr.uptime-kuma;

  dataDir = "/srv/storage/private/uptime-kuma";
in

{
  reservePortsFor = [ "uptime-kuma" ];

  users.users.uptime-kuma = {
    isSystemUser = true;
    home = "${dataDir}/.home";
    group = "uptime-kuma";
  };

  users.groups.uptime-kuma = {};

  systemd.tmpfiles.rules = [
    "d '${dataDir}' 0700 uptime-kuma uptime-kuma - -"
  ];

  systemd.services.uptime-kuma = {

    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      User = "uptime-kuma";
      Group = "uptime-kuma";

      ProtectSystem = "strict";
      ReadWritePaths = [ dataDir ];
      ProtectHome = "tmpfs";
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_NETLINK"
      ];
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      PrivateUsers = true;
      LockPersonality = true;
      SystemCallArchitectures = [ "native" ];

      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;

      ExecStart = flakePkgs.uptime-kuma + /bin/uptime-kuma;
    };


    environment = {
      NODE_ENV = "production";
      DATA_DIR = dataDir;
      UPTIME_KUMA_HOST = "127.0.0.1";
      UPTIME_KUMA_PORT = port;
      UPTIME_KUMA_HIDE_LOG = lib.concatStringsSep "," [
        "debug_monitor"
        "info_monitor"
      ];
    };
  };

  services.nginx.virtualHosts."status.${domain}" = lib.recursiveUpdate (tools.nginx.vhosts.proxy "http://127.0.0.1:${port}") {
    locations = {
      "/".proxyWebsockets = true;
      "=/".return = "302 /status/${builtins.replaceStrings ["."] ["-"] domain}";
    };
  };
}
