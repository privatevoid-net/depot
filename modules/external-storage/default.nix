{ config, depot, lib, pkgs, ... }:

let
  inherit (depot.packages) s3ql;

  cfg = config.services.external-storage;

  create = lib.flip lib.mapAttrs';
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
    boot.supportedFilesystems = lib.mkIf (cfg.underlays != {}) [ "cifs" ];

    age.secrets = lib.mkMerge [
      (create cfg.underlays (name: ul: lib.nameValuePair "cifsCredentials-${name}" { file = ul.credentialsFile; }))
      (create cfg.fileSystems (name: fs: lib.nameValuePair "storageAuth-${name}" { file = fs.authFile; }))
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
          underlayPath = cfg.underlays.${fs.underlay}.mountpoint;

          backendUrl = if isUnderlay then "local://${underlayPath}" else fs.backend;

          fsType = if isUnderlay then "local" else lib.head (lib.strings.match "([a-z0-9]*)://.*" backendUrl);
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

          unitConfig.RequiresMountsFor = lib.mkIf isUnderlay underlayPath;

          serviceConfig = let
            commonOptions = [
              "--cachedir" fs.cacheDir
              "--authfile" config.age.secrets."storageAuth-${name}".path
            ] ++ (lib.optionals (fs.backendOptions != []) [ "--backend-options" (lib.concatStringsSep "," fs.backendOptions) ]);
          in {
            Type = "notify";

            ExecStartPre = map lib.escapeShellArgs [
              [
                (let
                  mkfsEncrypted = ''
                    ${pkgs.gnugrep}/bin/grep -m1 fs-passphrase: '${config.age.secrets."storageAuth-${name}".path}' \
                      | cut -d' ' -f2- \
                      | ${s3ql}/bin/mkfs.s3ql ${lib.escapeShellArgs commonOptions} -L '${name}' '${backendUrl}'
                  '';

                  mkfsPlain = ''
                    ${s3ql}/bin/mkfs.s3ql ${lib.escapeShellArgs commonOptions} --plain -L '${name}' '${backendUrl}'
                  '';

                  detectFs = {
                    local = "test -e ${underlayPath}/s3ql_metadata";
                  }.${fsType} or null;
                in pkgs.writeShellScript "create-s3ql-filesystem" (lib.optionalString (detectFs != null) ''
                  if ! ${detectFs}; then
                    echo Creating new S3QL filesystem on ${backendUrl}
                    ${if fs.encrypt then mkfsEncrypted else mkfsPlain}
                  fi
                ''))
              ]
              [
                "${pkgs.coreutils}/bin/install" "-dm755" fs.mountpoint
              ]
              ([
                "${s3ql}/bin/fsck.s3ql"
                backendUrl
                "--compress" "none"
              ] ++ commonOptions)
            ];

            ExecStart = lib.escapeShellArgs ([
              "${s3ql}/bin/mount.s3ql"
              backendUrl
              fs.mountpoint
              "--fs-name" "${fs.unitName}"
              "--allow-other"
              "--systemd" "--fg"
              "--log" "none"
              "--compress" "none"
            ] ++ commonOptions);

            ExecStop = lib.escapeShellArgs [
              "${s3ql}/bin/umount.s3ql"
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

            # see https://www.rath.org/s3ql-docs/man/fsck.html
            SuccessExitStatus = [ 128 ];
          };
        };
      });
    };
  };
}
