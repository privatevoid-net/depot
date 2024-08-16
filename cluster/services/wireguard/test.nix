{ cluster, lib, ... }:

{
  defaults.options.services.locksmith = lib.mkSinkUndeclaredOptions { };

  testScript = ''
    start_all()
    ${lib.pipe cluster.config.services.wireguard.nodes.mesh [
      (map (node: /*python*/ ''
        ${node}.wait_for_unit("wireguard-wgmesh.target")
      ''))
      (lib.concatStringsSep "\n")
    ]}

    ${lib.pipe cluster.config.services.wireguard.nodes.mesh [
      (map (node: /*python*/ ''
        with subtest("${node} can reach all other nodes"):
          ${lib.pipe (cluster.config.services.wireguard.otherNodes.mesh node) [
            (map (peer: /*python*/ ''
              ${node}.succeed("ping -c3 ${cluster.config.hostLinks.${peer}.mesh.extra.meshIp}")
            ''))
            (lib.concatStringsSep "\n  ")
          ]}
      ''))
      (lib.concatStringsSep "\n")
    ]}
  '';
}
