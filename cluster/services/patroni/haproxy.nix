{ cluster, ... }:

let
  inherit (cluster.config) vars;

  internalPort = cluster.config.links.patroni-pg-internal.portStr;

  checkPort = cluster.config.links.patroni-api.portStr;

  nodes = cluster.config.services.patroni.nodes.worker;

  getMeshIp = name: vars.mesh.${name}.meshIp;

  mkServerString = name: "server pg_ha_${name}_${internalPort} ${getMeshIp name}:${internalPort} maxconn 200 check port ${checkPort}";
in

{
  services.haproxy = {
    enable = true;
    config = ''
      global
          maxconn 200
      
      defaults
          log global
          mode tcp
          retries 2
          timeout client 30m
          timeout connect 4s
          timeout server 30m
          timeout check 5s
      
      listen patroni
          bind ${cluster.config.links.patroni-pg-access.tuple}
          option httpchk
          http-check expect status 200
          default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
          ${builtins.concatStringsSep "    \n" (map mkServerString nodes)}
    '';
  };
  systemd.services.haproxy.aliases = [ "postgresql.service" ];
}
