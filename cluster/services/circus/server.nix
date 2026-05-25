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
    package = depot'.inputs.circus.packages.fc-server;
    evaluatorPackage = depot'.inputs.circus.packages.fc-evaluator;
    queueRunnerPackage = depot'.inputs.circus.packages.fc-queue-runner;
    migratePackage = depot'.inputs.circus.packages.fc-migrate-cli;
    server.enable = true;
    evaluator.enable = true;
    queueRunner.enable = true;
    settings = {
      server = {
        host = link.ipv4;
        inherit (link) port;
      };
      evaluator = {
        poll_interval = 600;
      };
      queue_runner = {
        poll_interval = 30;
      };
    };
  };
}
