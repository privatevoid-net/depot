{ config, lib, pkgs, ... }:

let
  s3qlWithSystemd = pkgs.s3ql.overrideAttrs (old: {
    propagatedBuildInputs = old.propagatedBuildInputs ++ [
      pkgs.python3Packages.systemd
    ];
  });

  dirs = {
    cache = "/srv/storage/private/s3ql-cache";
    underlay = "/mnt/heresy";
    mount = "/srv/heresy";
  };
in

{
  age.secrets = {
    storageBoxCredentials.file = ./secrets/storage-box-credentials.age;
    heresyEncryptionKey.file = ./secrets/heresy-encryption-key.age;
  };

  boot.supportedFilesystems = [ "cifs" ];

  fileSystems."${dirs.underlay}" = {
    fsType = "cifs";
    device = "//u357754.your-storagebox.de/u357754-sub1/fs/heresy";
    options = [
      "credentials=${config.age.secrets.storageBoxCredentials.path}"
      "dir_mode=0700"
      "file_mode=0600"
      "_netdev"
      "x-systemd.automount"
    ];
  };

  systemd = {
    tmpfiles.rules = [
      "d '${dirs.cache}' 0700 root root - -"
    ];
    services.heresy = {
      description = "Heresy Filesystem";
      wantedBy = [ "multi-user.target" ];
      requires = [ "mnt-heresy.mount" ];
      wants = [ "remote-fs.target" ];
      after = [ "mnt-heresy.mount" ];
      before = [ "remote-fs.target" ];

      # used by umount.s3ql
      path = with pkgs; [
        psmisc
        util-linux
      ];

      serviceConfig = let
        commonOptions = [
          "--compress" "none"
          "--cachedir" dirs.cache
          "--authfile" config.age.secrets.heresyEncryptionKey.path
        ];
      in {
        Type = "notify";

        ExecStartPre = map lib.escapeShellArgs [
          [
            "${pkgs.coreutils}/bin/install" "-dm755" dirs.mount
          ]
          ([
            "${s3qlWithSystemd}/bin/fsck.s3ql"
            "local://${dirs.underlay}"
          ] ++ commonOptions)
        ];
        ExecStart = lib.escapeShellArgs ([
          "${s3qlWithSystemd}/bin/mount.s3ql"
          "local://${dirs.underlay}"
          dirs.mount
          "--fs-name" "heresy"
          "--allow-other"
          "--systemd" "--fg"
          "--log" "none"
        ] ++ commonOptions);

        ExecStop = lib.escapeShellArgs [
          "${s3qlWithSystemd}/bin/umount.s3ql"
          "--log" "none"
          dirs.mount
        ];

        # fsck and unmounting might take a while
        TimeoutStartSec = "600s";
        TimeoutStopSec = "600s";

        # s3ql only handles SIGINT
        KillSignal = "SIGINT";

        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  };
}
