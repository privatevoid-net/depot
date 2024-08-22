{ config, lib, ... }:

{
  hostLinks = lib.pipe config.services [
    (lib.filterAttrs (_: svc: svc.meshLinks != {}))
    (lib.mapAttrsToList (svcName: svc:
      lib.mapAttrsToList (groupName: links:
        lib.genAttrs svc.nodes.${groupName} (hostName: lib.mapAttrs (_: cfg: { ... }: {
          imports = [ cfg.link ];
          ipv4 = config.vars.mesh.${hostName}.meshIp;
        }) links)
      ) svc.meshLinks
    ))
    (map lib.mkMerge)
    lib.mkMerge
  ];
}
