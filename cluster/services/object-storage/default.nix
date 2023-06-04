{ tools, ... }:

{
  services.object-storage = {
    nodes.host = [ "VEGAS" ];
    nixos.host = ./host.nix;
  };

  monitoring.blackbox.targets.object-storage = {
    address = "https://object-storage.${tools.meta.domain}/minio/health/live";
    module = "https2xx";
  };
}
