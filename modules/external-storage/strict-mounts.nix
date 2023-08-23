{ config, lib, ... }:

let
  cfg = config.services.external-storage;
in

with lib;
{
  options.systemd.services = mkOption {
    type = with types; attrsOf (submodule ({ config, ... }: {
      config = mkIf (config.strictMounts != []) (let
        findFilesystemsFor = mount: pipe cfg.fileSystems [
          (filterAttrs (_: fs: hasPrefix "${fs.mountpoint}/" "${mount}/"))
          (mapAttrsToList (_: fs: "${fs.unitName}.service"))
        ];
        services = flatten (map findFilesystemsFor config.strictMounts);
      in {
        after = services;
        bindsTo = services;
      });
    }));
  };
}
