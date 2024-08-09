{ config, depot, lib, pkgs, ... }:

let
  inherit (depot.packages) s3ql;

  cfg = config.services.external-storage;

  cfgAge = config.age;

  create = lib.flip lib.mapAttrs';

  createFiltered = pred: attrs: f: create (lib.filterAttrs pred attrs) f;
in

{
  imports = [
    ./strict-mounts.nix
  ];

  options = {
    services.external-storage = {
      fileSystems = lib.mkOption {
        description = "S3QL-based filesystems on top of CIFS mountpoints.";
        default = {};
        type = with lib.types; lazyAttrsOf (submodule ({ config, name, ... }: let
          authFile = if config.locksmithSecret != null then
            "/run/locksmith/${config.locksmithSecret}"
          else
            cfgAge.secrets."storageAuth-${name}".path;
        in {
          imports = [ ./filesystem-type.nix ];
          backend = lib.mkIf (config.underlay != null) "local://${cfg.underlays.${config.underlay}.mountpoint}";
          commonArgs = [
            "--cachedir" config.cacheDir
            "--authfile" authFile
          ] ++ (lib.optionals (config.backendOptions != []) [ "--backend-options" (lib.concatStringsSep "," config.backendOptions) ]);
        }));
      };
      underlays = lib.mkOption {
        description = "CIFS underlays for S3QL filesystems.";
        default = {};
        type = with lib.types; lazyAttrsOf (submodule ./underlay-type.nix);
      };
    };
  };

  config = {
    system.extraIncantations = {
      runS3qlUpgrade = i: filesystem: let
        fs = cfg.fileSystems.${filesystem};
      in i.execShellWith [ s3ql ] ''
        echo yes | ${lib.escapeShellArgs
          ([
            "${s3ql}/bin/s3qladm"
          ] ++ fs.commonArgs ++ [
            "upgrade"
            fs.backend
          ])
        }
      '';
    };

    boot.supportedFilesystems = lib.mkIf (cfg.underlays != {}) [ "cifs" ];

    age.secrets = lib.mkMerge [
      (create cfg.underlays (name: ul: lib.nameValuePair "cifsCredentials-${name}" { file = ul.credentialsFile; }))
      (createFiltered (_: fs: fs.locksmithSecret == null) cfg.fileSystems (name: fs: lib.nameValuePair "storageAuth-${name}" { file = fs.authFile; }))
    ];

    services.locksmith.waitForSecrets = createFiltered (_: fs: fs.locksmithSecret != null) cfg.fileSystems (name: fs: {
      name = fs.unitName;
      value = [ fs.locksmithSecret ];
    });

    fileSystems = create cfg.underlays (name: ul: {
      name = ul.mountpoint;
      value = {
        fsType = "cifs";
        device = "//${ul.host}/${ul.storageBoxAccount}-${ul.subUser}${ul.path}";
        options = [
          "credentials=${config.age.secrets."cifsCredentials-${name}".path}"
          "dir_mode=0700"
          "file_mode=0600"
          "uid=${toString ul.uid}"
          "gid=${toString ul.gid}"
          "forceuid"
          "forcegid"
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
          isUnderlay = fs.underlay != null;

          backendParts = lib.strings.match "([a-z0-9]*)://([^/]*)/([^/]*)(/.*)?" fs.backend;

          fsType = if isUnderlay then "local" else lib.head backendParts;

          s3Endpoint = assert fsType == "s3c4"; lib.elemAt backendParts 1;

          s3Bucket = assert fsType == "s3c4"; lib.elemAt backendParts 2;

          localBackendPath = if isUnderlay then cfg.underlays.${fs.underlay}.mountpoint else lib.head (lib.strings.match "[a-z0-9]*://(/.*)" fs.backend);
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

          unitConfig.RequiresMountsFor = lib.mkIf isUnderlay localBackendPath;

          serviceConfig = {
            Type = "notify";

            ExecStartPre = map lib.escapeShellArgs [
              [
                (let
                  authFile = if fs.locksmithSecret != null then
                    "/run/locksmith/${fs.locksmithSecret}"
                  else
                    cfgAge.secrets."storageAuth-${name}".path;
                  mkfsEncrypted = ''
                    ${pkgs.gnugrep}/bin/grep -m1 fs-passphrase: '${authFile}' \
                      | cut -d' ' -f2- \
                      | ${s3ql}/bin/mkfs.s3ql ${lib.escapeShellArgs fs.commonArgs} -L '${name}' '${fs.backend}'
                  '';

                  mkfsPlain = ''
                    ${s3ql}/bin/mkfs.s3ql ${lib.escapeShellArgs fs.commonArgs} --plain -L '${name}' '${fs.backend}'
                  '';

                  detectFs = {
                    local = "test -e ${localBackendPath}/s3ql_metadata";
                    s3c4 = pkgs.writeShellScript "detect-s3ql-filesystem" ''
                      export AWS_ACCESS_KEY_ID="$(${pkgs.gnugrep}/bin/grep -m1 backend-login: '${authFile}' | cut -d' ' -f2-)"
                      export AWS_SECRET_ACCESS_KEY="$(${pkgs.gnugrep}/bin/grep -m1 backend-password: '${authFile}' | cut -d' ' -f2-)"
                      ${pkgs.s5cmd}/bin/s5cmd --endpoint-url https://${s3Endpoint}/ ls 's3://${s3Bucket}/s3ql_params' >/dev/null
                    '';
                  }.${fsType} or null;
                in pkgs.writeShellScript "create-s3ql-filesystem" (lib.optionalString (detectFs != null) ''
                  if ! ${detectFs}; then
                    echo Creating new S3QL filesystem on ${fs.backend}
                    ${if fs.encrypt then mkfsEncrypted else mkfsPlain}
                  fi
                ''))
              ]
              [
                "${pkgs.coreutils}/bin/install" "-dm755" fs.mountpoint
              ]
              ([
                "${s3ql}/bin/fsck.s3ql"
                fs.backend
                "--compress" "none"
              ] ++ fs.commonArgs)
            ];

            ExecStart = lib.escapeShellArgs ([
              "${s3ql}/bin/mount.s3ql"
              fs.backend
              fs.mountpoint
              "--fs-name" "${fs.unitName}"
              "--allow-other"
              "--systemd" "--fg"
              "--log" "none"
              "--compress" "none"
            ] ++ fs.commonArgs);

            ExecStop = pkgs.writeShellScript "umount-s3ql-filesystem" ''
              if grep -qw '${fs.mountpoint}' /proc/self/mounts; then
                ${s3ql}/bin/umount.s3ql --log none '${fs.mountpoint}'
              else
                echo Filesystem already unmounted.
              fi
              echo "Waiting for MainPID ($MAINPID) to die..."
              tail --pid=$MAINPID -f /dev/null
            '';

            # fsck and unmounting might take a while
            TimeoutStartSec = "6h";
            TimeoutStopSec = "900s";

            # s3ql only handles SIGINT
            KillSignal = "SIGINT";

            Restart = "on-failure";
            RestartSec = "10s";

            # see https://www.rath.org/s3ql-docs/man/fsck.html
            SuccessExitStatus = [ 128 ];
          };
        };
      });
    };
  };
}
