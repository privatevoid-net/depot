{ cluster, config, depot, lib, ... }:

let
  apiLink = cluster.config.hostLinks.${config.networking.hostName}.frangiclave-server;
  clusterLink = cluster.config.hostLinks.${config.networking.hostName}.frangiclave-cluster;
in

{
  services.vault = {
    enable = true;
    package = depot.packages.openbao;
    address = apiLink.tuple;
    extraConfig = /*hcl*/ ''
      api_addr = "${apiLink.url}"
      cluster_addr = "${clusterLink.url}"
    '';

    storageBackend = "raft";
    storageConfig = /*hcl*/ ''
      node_id = "x${builtins.hashString "sha256" "frangiclave-node-${config.networking.hostName}"}"
      ${
        lib.pipe (cluster.config.services.frangiclave.otherNodes.server config.networking.hostName) [
          (map (node: cluster.config.hostLinks.${node}.frangiclave-server))
          (map (link: /*hcl*/ ''
            retry_join {
              leader_api_addr = "${link.url}"
            }
          ''))
          (lib.concatStringsSep "\n")
        ]
      }
    '';
  };
}
