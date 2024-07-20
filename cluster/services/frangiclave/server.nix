{ cluster, config, depot, ... }:

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
    '';
  };
}
