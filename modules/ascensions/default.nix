{ config, lib, pkgs, ... }:

with lib;

let
  ascensionsDir = "/var/lib/ascensions";

  ascensionType = { name, ... }: {
    options = {
      incantations = mkOption {
        type = with types; functionTo (listOf package);
        default = i: [];
      };
      distributed = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to perform a distributed ascension using Consul KV.";
      };
      requiredBy = mkOption {
        type = with types; listOf str;
        default = [ "${name}.service" ];
        description = "Services that require this ascension.";
      };
      before = mkOption {
        type = with types; listOf str;
        default = [];
        description = "Run the ascension before these services.";
      };
      after = mkOption {
        type = with types; listOf str;
        default = [];
        description = "Run the ascension after these services.";
      };
    };
  };

  builtinIncantations = with pkgs; rec {
    execShellWith = extraPackages: script: writeShellScript "incantation" ''
      export PATH='${makeBinPath ([ coreutils ] ++ extraPackages)}'
      ${script}
    '';

    execShell = execShellWith [];

    multiple = incantations: execShell (concatStringsSep " && " incantations);

    move = from: to: execShell ''
      test -e ${escapeShellArg from} && rm -rf ${escapeShellArg to}
      mkdir -p "$(dirname ${escapeShellArg to})"
      mv ${escapeShellArgs [ from to ]}
    '';

    chmod = mode: target: "chmod -R ${escapeShellArgs [ mode target ]}";
  };

  allIncantations = builtinIncantations // mapAttrs (_: mk: mk allIncantations) config.system.extraIncantations;

  runIncantations = f: f allIncantations;

  consul = config.services.consul.package;
in

{
  options.system = {
    ascensions = mkOption {
      type = with types; attrsOf (submodule ascensionType);
      default = {};
    };
    extraIncantations = mkOption {
      type = with types; attrsOf (functionTo raw);
      default = {};
    };
  };

  config = {
    systemd = {
      tmpfiles.rules = [
        "d ${ascensionsDir} 0755 root root - -"
      ];

      services = mapAttrs' (name: asc: {
        name = "ascend-${name}";
        value = let
          incantations = runIncantations asc.incantations;
          targetLevel = toString (length incantations);
        in {
          description = "Ascension for ${name}";
          wantedBy = [ "multi-user.target" ];
          inherit (asc) requiredBy before;
          after = asc.after ++ (lib.optional asc.distributed "consul-ready.service");
          requires = lib.optional asc.distributed "consul-ready.service";
          serviceConfig.Type = "oneshot";
          distributed.enable = asc.distributed;
          script = ''
            incantations=(${concatStringsSep " " incantations})
            ${if asc.distributed then /*bash*/ ''
              getLevel() {
                ${consul}/bin/consul kv get 'ascensions/${name}/currentLevel'
              }
              setLevel() {
                ${consul}/bin/consul kv put 'ascensions/${name}/currentLevel' "$1" >/dev/null
              }
              isEmpty() {
                ! getLevel >/dev/null 2>/dev/null
              }
            '' else /*bash*/ ''
              levelFile='${ascensionsDir}/${name}'
              getLevel() {
                echo "$(<"$levelFile")"
              }
              setLevel() {
                echo "$1" > "$levelFile"
              }
              isEmpty() {
                [[ ! -e "$levelFile" ]]
              }
            ''
            }
            if isEmpty; then
              setLevel '${targetLevel}'
              echo Initializing at level ${targetLevel}
              exit 0
            fi
            cur=$(getLevel)
            echo Current level: $cur
            for lvl in $(seq $(($cur+1)) ${targetLevel}); do
              echo Running incantation for level $lvl...
              ''${incantations[$((lvl-1))]}
              setLevel "$lvl"
            done
            echo All incantations complete, ascended to level $(getLevel)
          '';
        };
      }) config.system.ascensions;
    };
  };
}
