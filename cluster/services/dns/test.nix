{ cluster, lib, ... }:

let
  inherit (cluster._module.specialArgs.depot.lib.meta) domain;
in
{
  nodes = {
    nowhere = { pkgs, ... }: {
      passthru = cluster;
      environment.systemPackages = [
        pkgs.knot-dns
        pkgs.openssl
      ];
    };
  } // (lib.genAttrs cluster.config.services.dns.nodes.coredns (_: {
    systemd.targets.test-acme-ready = {
      wantedBy = [ "multi-user.target" ];
      wants = [ "acme-order-renew-securedns.${domain}.service" ];
      after = [ "acme-order-renew-securedns.${domain}.service"];
    };
  }));

  testScript = ''
    import json
    nodeNames = json.loads('${builtins.toJSON cluster.config.services.dns.nodes.authoritative}')
    dotNames = json.loads('${builtins.toJSON cluster.config.services.dns.nodes.coredns}')
    nodes = [ n for n in machines if n.name in nodeNames ]
    dotServers = [ n for n in machines if n.name in dotNames ]

    start_all()

    with subtest("should allow external name resolution for own domain"):
      for node in nodes:
        node.wait_for_unit("coredns.service")
      nowhere.wait_until_succeeds("[[ $(kdig +short securedns.${domain} | wc -l) -ne 0 ]]", timeout=60)
      nowhere.fail("[[ $(kdig +short example.com | wc -l) -ne 0 ]]")

    with subtest("should have valid certificate on DoT endpoint"):
      for node in dotServers:
        node.wait_for_unit("test-acme-ready.target")
      nowhere.wait_until_succeeds("openssl </dev/null s_client -connect securedns.${domain}:853 -verify_return_error -strict -verify_hostname securedns.${domain}", timeout=60)
  '';
}
