{ cluster, config, lib, ... }:

let
  inherit (cluster._module.specialArgs.depot.lib.meta) domain;
in

{
  nodes = lib.mkMerge [
    {
      nowhere = { pkgs, ... }: {
        networking.firewall.allowedTCPPorts = [ 8080 ];
        systemd.services.ways-simple-service = let
          webroot = pkgs.writeTextDir "example.txt" "hello world";
        in {
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.darkhttpd}/bin/darkhttpd ${webroot} --port 8080";
            DynamicUser = true;
          };
        };
      };
    }
    (lib.genAttrs cluster.config.services.ways.nodes.host (lib.const {
      services.nginx.upstreams.nowhere.servers = {
        "${(builtins.head config.nodes.nowhere.networking.interfaces.eth1.ipv4.addresses).address}:8080" = {};
      };
      consul.services.ways-test-service = {
        unit = "consul";
        mode = "external";
        definition = {
          name = "ways-test-service";
          address = (builtins.head config.nodes.nowhere.networking.interfaces.eth1.ipv4.addresses).address;
          port = 8080;
        };
      };
      systemd.targets.test-acme-ready = {
        wantedBy = [ "multi-user.target" ];
        wants = [ "acme-order-renew-ways-test-simple.${domain}.service" ];
        after = [ "acme-order-renew-ways-test-consul.${domain}.service"];
      };
    }))
  ];

  testScript = ''
    import json
    nodeNames = json.loads('${builtins.toJSON cluster.config.services.ways.nodes.host}')
    nodes = [ n for n in machines if n.name in nodeNames ]

    start_all()
    nowhere.wait_for_unit("multi-user.target")
    for node in nodes:
      node.wait_for_unit("multi-user.target")
      node.wait_for_unit("test-acme-ready.target")

    with subtest("single-target service"):
      nowhere.succeed("curl -f https://ways-test-simple.${domain}")

    with subtest("consul-managed service"):
      nowhere.succeed("curl -f https://ways-test-consul.${domain}")
  '';
}
