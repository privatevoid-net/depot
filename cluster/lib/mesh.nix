{ config, lib, ... }:

{
  hostLinks = lib.pipe config.services [
    (lib.filterAttrs (_: svc: svc.meshLinks != {}))
    (lib.mapAttrsToList (svcName: svc: lib.mapAttrsToList (name: cfg: lib.genAttrs svc.nodes.${name} (hostName: {
      ${cfg.name} = { ... }: {
        imports = [ cfg.link ];
        ipv4 = config.vars.mesh.${hostName}.meshIp;
      };
    })) svc.meshLinks))
    (map lib.mkMerge)
    lib.mkMerge
  ];
}
