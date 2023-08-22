{ config, lib, pkgs, ... }:

let
  s3qlWithSystemd = pkgs.s3ql.overrideAttrs (old: {
    propagatedBuildInputs = old.propagatedBuildInputs ++ [
      pkgs.python3Packages.systemd
    ];
  });

  cfg = config.services.external-storage;

  create = lib.flip lib.mapAttrs';
in

{
  options = {
    services.external-storage = {
      fileSystems = lib.mkOption {
        description = "S3QL-based filesystems on top of CIFS mountpoints.";
        default = {};
        type = with lib.types; lazyAttrsOf (submodule ./filesystem-type.nix);
      };
      underlays = lib.mkOption {
        description = "CIFS underlays for S3QL filesystems.";
        default = {};
        type = with lib.types; lazyAttrsOf (submodule ./underlay-type.nix);
      };
    };
  };

  config = {
    boot.supportedFilesystems = [ "cifs" ];

    age.secrets = lib.mkMerge [
      (create cfg.underlays (name: ul: lib.nameValuePair "cifsCredentials-${name}" { file = ul.credentialsFile; }))
      (create cfg.fileSystems (name: fs: lib.nameValuePair "storageEncryptionKey-${name}" { file = fs.encryptionKeyFile; }))
    ];

    fileSystems = create cfg.underlays (name: ul: {
      name = ul.mountpoint;
      value = {
        fsType = "cifs";
        device = "//${ul.host}/${ul.storageBoxAccount}-${ul.subUser}${ul.path}";
        options = [
          "credentials=${config.age.secrets."cifsCredentials-${name}".path}"
          "dir_mode=0700"
          "file_mode=0600"
          "seal"
          "hard"
          "resilienthandles"
          "cache=loose"
          "_netdev"
          "x-systemd.automount"
        ];
      };
    });
    systemd = {
      tmpfiles.rules = lib.mapAttrsToList (_: fs: "d '${fs.cacheDir}' 0700 root root - -") cfg.fileSystems;

      mounts = lib.mapAttrsToList (name: fs: {
        where = fs.mountpoint;
        what = name;
        requires = [ "${fs.unitName}.service" ];
        after = [ "${fs.unitName}.service" ];
      }) cfg.fileSystems;

      services = create cfg.fileSystems (name: fs: {
        name = fs.unitName;
        value = let
          underlayPath = cfg.underlays.${fs.underlay}.mountpoint;
        in {
          description = fs.unitDescription;
          wantedBy = [ "multi-user.target" ];
          wants = [ "remote-fs.target" ];
          before = [ "remote-fs.target" ];

          # used by umount.s3ql
          path = with pkgs; [
            psmisc
            util-linux
          ];

          unitConfig.RequiresMountsFor = underlayPath;

          serviceConfig = let
            commonOptions = [
              "--cachedir" fs.cacheDir
              "--authfile" config.age.secrets."storageEncryptionKey-${name}".path
            ];
          in {
            Type = "notify";

            ExecStartPre = map lib.escapeShellArgs [
              [
                (pkgs.writeShellScript "create-s3ql-filesystem" ''
                  if ! test -e ${underlayPath}/s3ql_passphrase; then
                    echo Creating new S3QL filesystem on ${underlayPath}
                    ${pkgs.gnugrep}/bin/grep -m1 fs-passphrase: '${config.age.secrets."storageEncryptionKey-${name}".path}' \
                      | cut -d' ' -f2- \
                      | ${s3qlWithSystemd}/bin/mkfs.s3ql ${lib.escapeShellArgs commonOptions} -L '${name}' 'local://${underlayPath}'
                  fi
                '')
              ]
              [
                "${pkgs.coreutils}/bin/install" "-dm755" fs.mountpoint
              ]
              ([
                "${s3qlWithSystemd}/bin/fsck.s3ql"
                "local://${underlayPath}"
                "--compress" "none"
              ] ++ commonOptions)
            ];

            ExecStart = lib.escapeShellArgs ([
              "${s3qlWithSystemd}/bin/mount.s3ql"
              "local://${underlayPath}"
              fs.mountpoint
              "--fs-name" "${fs.unitName}"
              "--allow-other"
              "--systemd" "--fg"
              "--log" "none"
              "--compress" "none"
            ] ++ commonOptions);

            ExecStop = lib.escapeShellArgs [
              "${s3qlWithSystemd}/bin/umount.s3ql"
              "--log" "none"
              fs.mountpoint
            ];

            # fsck and unmounting might take a while
            TimeoutStartSec = "6h";
            TimeoutStopSec = "900s";

            # s3ql only handles SIGINT
            KillSignal = "SIGINT";

            Restart = "on-failure";
            RestartSec = "10s";
          };
        };
      });
    };
  };
}
