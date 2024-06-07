{ config, lib, ... }:

{
  system.ascensions = lib.mapAttrs' (name: fs: {
    name = "s3ql-${name}";
    value = {
      requiredBy = [ "${fs.unitName}.service" ];
      before = [ "${fs.unitName}.service" ];
      incantations = i: [
        (i.runS3qlUpgrade name) # 4.0.0 -> 5.1.3
      ];
    };
  }) config.services.external-storage.fileSystems;
}
