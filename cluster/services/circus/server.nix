{ cluster, config, depot, depot', ... }:

let
  link = cluster.config.hostLinks.${config.networking.hostName}.circusServer;
in

{
  imports = [
    depot.inputs.circus.nixosModules.default
  ];

  services.fc-ci = {
    enable = true;
    package = depot'.inputs.circus.packages.circus-server;
    migratePackage = depot'.inputs.circus.packages.circus-migrate-cli;
    server.enable = true;
    settings = {
      server = {
        host = link.ipv4;
        inherit (link) port;
      };
    };
  };
}
