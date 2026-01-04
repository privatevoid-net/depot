{ cluster, config, depot', lib, pkgs, ... }:

let
  inherit (cluster.config.services.planetarium) secrets;
  toml = pkgs.formats.toml { };

  cfg = config.storage.planetarium;
  privateDir = "/srv/planetarium/private";
  setupDir = "/srv/planetarium/.setup";
in

{
  options.storage.planetarium = with lib; {
    fileSystems = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          mountPoint = mkOption {
            type = types.path;
            default = "${privateDir}/${name}";
          };

          setupMountPoint = mkOption {
            type = types.path;
            default = "${setupDir}/${name}";
            readOnly = true;
            internal = true;
          };

          uid = mkOption {
            type = types.int;
            default = 0;
          };

          gid = mkOption {
            type = types.int;
            default = 0;
          };

          mode = mkOption {
            type = types.str;
            default = "0700";
          };

          keyFile = mkOption {
            type = types.path;
          };

          storagePath = mkOption {
            type = types.str;
            default = "s3://ib92eldmnvv1ofyrja5dmyizsfkivw4f-privatevoid-net-zerofs/P/${name}";
          };

          s3Endpoint = mkOption {
            type = types.str;
            default = "https://fsn1.your-objectstorage.com";
          };

          s3Region = mkOption {
            type = types.str;
            default = "fsn1";
          };
        };
      }));
      default = { };
    };
  };

  config = lib.mkIf (cfg.fileSystems != { }) {
    systemd = {
      tmpfiles.settings.planetarium = {
        ${privateDir}.d.mode = "0751";
        ${setupDir}.d.mode = "0700";
      };

      services = lib.mkMerge [
        (lib.mapAttrs' (name: fs: let
          zerofsConfig = toml.generate "zerofs-${name}.toml" {
            cache = {
              dir = "\${CACHE_DIRECTORY}";
              disk_size_gb = 10;
              memory_size_gb = 1;
            };

            storage = {
              url = "${fs.storagePath}/${lib.versions.majorMinor depot'.packages.zerofs.version}/";
              encryption_password = "\${ZEROFS_KEY}";
            };

            aws = {
              access_key_id = "\${AWS_ACCESS_KEY_ID}";
              secret_access_key = "\${AWS_SECRET_ACCESS_KEY}";
              endpoint = fs.s3Endpoint;
              default_region = fs.s3Region;
            };

            servers.ninep = {
              addresses = [];
              unix_socket = "/run/zerofs/${name}/zerofs.sock";
            };
          };
        in {
          name = "zerofs-${name}";
          value = {
            description = "ZeroFS: ${name}";
            requires = [ "network.target" ];
            after = [ "network.target" ];
            serviceConfig = {
              DynamicUser = true;
              Type = "notify";
              NotifyAccess = "all";
              CacheDirectory = "zerofs-${name}";
              RuntimeDirectory = "zerofs/${name}";
              RuntimeDirectoryMode = "0700";
              EnvironmentFile = [ secrets.storageCredentials.path fs.keyFile ];
              Restart = "on-failure";
              RestartSec = "10s";
            };
            script = ''
              enable sleep
              (
              while ! test -e '/run/zerofs/${name}/zerofs.sock'; do
                  sleep .5
              done
              systemd-notify --ready
              ) & disown
              exec ${depot'.packages.zerofs}/bin/zerofs run --config ${zerofsConfig}
            '';
          };
        }) config.storage.planetarium.fileSystems)

        (lib.mapAttrs' (name: fs: {
          name = "planetarium-setup-${name}";
          value = {
            description = "Set up Planetarium Directory: ${name}";
            unitConfig = {
              RequiresMountsFor = [ fs.setupMountPoint ];
            };
            serviceConfig = {
              Type = "oneshot";
              ProtectSystem = "strict";
              CapabilityBoundingSet = [ "CAP_CHOWN" "CAP_FOWNER" ];
              ReadWritePaths = [ setupDir ];
            };
            script = ''
              chmod ${lib.escapeShellArg fs.mode} ${fs.setupMountPoint}
              chown ${toString fs.uid}:${toString fs.gid} ${fs.setupMountPoint}
            '';
          };
        }) config.storage.planetarium.fileSystems)
      ];

      mounts = let
        createMount = type: lib.mapAttrsToList (name: fs: {
          description = {
            mountPoint = "Planetarium Directory: ${name}";
            setupMountPoint = "Planetarium Setup Directory: ${name}";
          }.${type};
          after = [ "zerofs-${name}.service" ]
            ++ lib.optional (type == "mountPoint") "planetarium-setup-${name}.service";
          wants = lib.optional (type == "mountPoint") "planetarium-setup-${name}.service";
          bindsTo = [ "zerofs-${name}.service" ]
            ++ lib.optional (type == "setupMountPoint") "planetarium-setup-${name}.service";
          what = "/run/zerofs/${name}/zerofs.sock";
          where = fs.${type};
          type = "9p";
          options = "trans=unix,version=9p2000.L,cache=mmap,_netdev";
        }) config.storage.planetarium.fileSystems;
      in lib.mkMerge [
        (createMount "mountPoint")
        (createMount "setupMountPoint")
      ];

      automounts = lib.mapAttrsToList (name: fs: {
        wantedBy = [ "local-fs.target" ];
        where = fs.mountPoint;
      }) config.storage.planetarium.fileSystems;
    };
  };
}
