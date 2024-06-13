{ config, depot, lib, pkgs, ... }:

let
  cid = "c-f32aebf5";
  link = config.links.${cid};
  root = "/var/lib/${cid}";
  home = "${root}/pfx";

  sptAki =  {
    release-3_8_0 = pkgs.fetchurl {
      url = "https://dev.sp-tarkov.com/SPT/Stable-releases/releases/download/3.8.0/RELEASE-SPT-3.8.0-29197-2dd4d91.7z";
      hash = "sha256-IRMzI+hQkoCmVJXkAV4c/b2l/MtLb98IwDftMbFTlxA=";
    };
    update-3_8_1 = pkgs.fetchurl {
      url = "https://spt-releases.modd.in/SPT-3.8.1-29197-d3ac83e.7z";
      hash = "sha256-3roQlHgi8CUtLKji2YZLNgo8s92eUv3a+AbKo7VFB2U=";
    };
  };

  installSpt = pkgs.writeShellScript "install-spt" ''
    mkdir spt
    cd spt
    ${pkgs.p7zip}/bin/7z x -y ${sptAki.release-3_8_0}
    ${pkgs.p7zip}/bin/7z x -y ${sptAki.update-3_8_1}
  '';
in

{
  links.${cid} = {
    protocol = "http";
    ipv4 = depot.reflection.interfaces.primary.addrPublic;
  };

  users.users.${cid} = {
    isNormalUser = true;
    group = cid;
    inherit home;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCvaZG+5642/jjqVaFGsS3DK0Jtg1wfMY4Yh20tFKtdcZEsLRy16KSJkPH447vP91pGkx8T+GJ1kXEw4dMR9dOKDwS2qCgHwAQbZ2V+/NNJ56bCzTo+geSc/imrWjiHQUhzPRcTyI6pVi3rVAhzEnAVjcC7a4LnLsIFW8Ill0kF8OR4tHoeDNCNN/0XOgZH4dIT9eQCyw4u5zOaw9W81eTL7K1PLmbAWW1+qd//C6CrpxpxNO/kAnOavkscK1uJSfGRcs7Vb5mKKV2J7Be0vxCVY8C8h1qcYcrzudTs9MbQAgFP00bVcvl/byd5CAccQ2wBfuwUdJBC4MV8HZ152biGds8sdCBDoxyvSqScaBFza0iHAXPEygvfx+gEW9KNssfBoiU50SJgWbQUp9gQoppATg8XHqUI03xUeVBRbTyf7UMd2Qk3slWPEnEXlzvjwKGxyLsI0WKdWtqALgKe7mDn+wDAG15CayACi4kgKkZh3VariRC5Ks17LJdLH67vBvs="
    ];
  };
  users.groups.${cid} = {};

  systemd.services.${cid} = {
    wantedBy = [ "multi-user.target" ];

    path = [
      pkgs.jq
      pkgs.wine64Packages.staging
      pkgs.tmux
    ];

    preStart = ''
      cd ${home}
      test -e drive_c || wine64 wineboot

      cd drive_c
      test -e spt || ${installSpt}

      cd spt
      jq < Aki_Data/Server/configs/http.json > .http-new.json \
        '.ip = "${link.ipv4}" | .port = ${link.portStr} | .backendIp = "${link.ipv4}" | .backendPort = ${link.portStr}'
      mv .http-new.json Aki_Data/Server/configs/http.json
    '';

    script = ''
      cd ${home}/drive_c/spt
      tmux new -s 0 -d wine64 Aki.Server.exe
      exec tmux wait-for stop
    '';

    environment = {
      WINEPREFIX = "${home}";
    };

    restartIfChanged = false;

    serviceConfig = {
      DynamicUser = true;
      User = cid;
      Group = cid;
      ReadWritePaths = [ home ];

      ExecStop = "${pkgs.wine64Packages.staging}/bin/wineserver --kill";
      Restart = "on-failure";

      CPUQuota = "75%";
      MemoryMax = "2G";
      MemorySwapMax = "2G";

      IPAddressDeny = [
        "10.0.0.0/8"
        "100.64.0.0/10"
        "169.254.0.0/16"
        "172.16.0.0/12"
        "192.0.0.0/24"
        "192.0.2.0/24"
        "192.168.0.0/16"
        "198.18.0.0/15"
        "198.51.100.0/24"
        "203.0.113.0/24"
        "240.0.0.0/4"
        "100::/64"
        "2001:2::/48"
        "2001:db8::/32"
        "fc00::/7"
        "fe80::/10"
      ];
      IPAddressAllow = lib.unique config.networking.nameservers;
    };
  };

  systemd.services."${cid}-backup" = {
    startAt = "04:00";

    script = ''
      cd ${home}/drive_c/spt/user
      tarball=".profiles-backup-$(date +%s).tar"
      final="profiles-backup-$(date +%Y-%m-%d-%H:%M:%S).tar.xz"
      ${pkgs.gnutar}/bin/tar cvf "$tarball" profiles/
      ${pkgs.xz}/bin/xz -9 "$tarball"
      mv "''${tarball}.xz" "$final"
      ${pkgs.rotate-backups}/bin/rotate-backups -S yes -q --daily 30 --weekly 12 -I 'profiles-backup-*.tar.xz' .
    '';

    unitConfig.ConditionPathExists = "${home}/drive_c/spt/user";

    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      User = cid;
      Group = cid;
      ReadWritePaths = [ home ];
      PrivateNetwork = true;
    };
  };

  systemd.services."${cid}-auto-restart" = {
    startAt = "05:00";

    script = ''
      echo -n "Service status: "
      if ! systemctl is-active '${cid}.service'; then
        echo Service not active.
        exit
      fi

      for i in {1..120}; do
        if test "$(${pkgs.iproute2}/bin/ss -H -tn 'cgroup = /sys/fs/cgroup/system.slice/${cid}.service' | wc -l)" != 0; then
          echo Service in use.
          exit
        fi
        sleep 1
      done

      echo Restarting service...
      systemctl restart --no-block '${cid}.service'
    '';

    unitConfig.ConditionPathExists = "${home}/drive_c/spt";

    serviceConfig = {
      Type = "oneshot";
    };
  };

  services.openssh.extraConfig = ''
    Match User ${cid}
      ChrootDirectory ${root}
      ForceCommand internal-sftp -d /pfx/drive_c
      AllowTcpForwarding no
      X11Forwarding no
      PasswordAuthentication no
  '';

  networking.firewall.allowedTCPPorts = [ link.port ];
}
