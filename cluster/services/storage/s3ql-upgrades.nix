{ config, lib, ... }:

{
  system.ascensions = lib.mapAttrs' (name: fs: {
    name = "s3ql-${name}";
    value = {
      requiredBy = [ "${fs.unitName}.service" ];
      before = [ "${fs.unitName}.service" ];
      incantations = i: [ ];
    };
  }) config.services.external-storage.fileSystems;
}
