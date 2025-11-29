{ cluster, config, lib, ... }:

{
  links = lib.mapAttrs' (name: fs: {
    name = "zerofsMount-${name}";
    value.protocol = "nfs";
  }) cluster.config.storage.zerofs.fileSystems;

  systemd = {
    mounts = lib.mapAttrsToList (name: fs: let
      link = config.links."zerofsMount-${name}";
    in {
      after = [ "haproxy.service" ];
      requires = [ "haproxy.service" ];
      what = "${link.ipv4}:/";
      where = fs.mountPoint;
      type = "nfs";
      options = "vers=3,nolock,tcp,port=${link.portStr},mountport=${link.portStr},async,rsize=1048576,wsize=1048576,hard,timeo=600";
    }) cluster.config.storage.zerofs.fileSystems;
  };

  boot.supportedFilesystems = [ "nfs" ];

  services.haproxy = {
    enable = true;
    config = lib.mkMerge (lib.mapAttrsToList (name: fs: let
        link = config.links."zerofsMount-${name}";
        mkServer = host: let
          hostLink = cluster.config.hostLinks.${host}."zerofs-${name}";
        in "server zerofs_${name}_${host} ${hostLink.tuple} maxconn 200 check";
      in ''
        listen zerofs_${name}
            bind ${link.tuple}
            option tcp-check
            default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
            ${lib.concatStringsSep "\n    " (map mkServer cluster.config.services.zerofs.nodes.server)}
      ''
    ) cluster.config.storage.zerofs.fileSystems);
  };
}
