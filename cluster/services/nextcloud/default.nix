{ config, depot, ... }:

{
  services.nextcloud = {
    nodes.host = [ "VEGAS" ];
    nixos.host = ./host.nix;
  };

  monitoring.blackbox.targets.nextcloud = {
    address = "https://storage.${depot.lib.meta.domain}/status.php";
    module = "nextcloudStatus";
  };

  dns.records.storage.target = map
    (node: depot.hours.${node}.interfaces.primary.addrPublic)
    config.services.nextcloud.nodes.host;
}
