{ config, inputs, lib, pkgs, tools, ... }:

let
  inherit (tools.meta) domain;

  flakePkgs = inputs.self.packages.${pkgs.system};

  mapPaths = lib.mapAttrsRecursive (
    path: value: lib.nameValuePair
      (lib.concatStringsSep "__" path)
      (builtins.toString value)
  );

  translateConfig = config: lib.listToAttrs (
    lib.collect
      (x: x ? name && x ? value)
      (mapPaths config)
  );

  port = config.portsStr.ghost;

  contentPath = "/srv/storage/private/ghost";
in

{

  age.secrets.ghost-secrets = {
    file = ../../../../secrets/ghost-secrets.age;
    mode = "0400";
  };

  reservePortsFor = [ "ghost" ];

  users.users.ghost = {
    isSystemUser = true;
    home = "${contentPath}/.home";
    group = "ghost";
  };

  users.groups.ghost = {};

  systemd.tmpfiles.rules = [
    "d '${contentPath}' 0700 ghost ghost - -"
    "d '${contentPath}/data' 0755 ghost ghost - -"
    "d '${contentPath}/logs' 0755 ghost ghost - -"
    "d '${contentPath}/themes' 0755 ghost ghost - -"
    "L+ '${contentPath}/themes/casper' - - - - ${flakePkgs.ghost}/lib/node_modules/ghost/content/themes/casper"
  ];

  systemd.services.ghost = {

    wantedBy = [ "multi-user.target" ];
    after = [ "mysql.service" ];

    serviceConfig = {
      User = "ghost";
      Group = "ghost";

      ProtectSystem = "strict";
      ReadWritePaths = [ contentPath ];
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

      ExecStart = flakePkgs.ghost + /bin/ghost;
      EnvironmentFile = config.age.secrets.ghost-secrets.path;
    };


    environment = translateConfig {
      NODE_ENV = "production";
      url = "https://blog.${domain}";

      database = {
        client = "mysql";

        connection = {
          host = "127.0.0.1";
          database = "ghost";
          user = "ghost";
          # TODO: set password in secrets
        };
      };
      server = {
        host = "127.0.0.1";
        inherit port;
      };

      privacy.useTinfoil = true;

      paths = {
        inherit contentPath;
      };
    };
  };

  services.nginx.virtualHosts."blog.${domain}" = tools.nginx.vhosts.proxy "http://127.0.0.1:${port}";

}
