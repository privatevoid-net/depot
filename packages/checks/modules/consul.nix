{ config, ... }:

{
  extraBaseModules = {
    services.consul.extraConfig.addresses.http = config.nodes.consul.networking.primaryIPAddress;
  };

  nodes.consul = { config, ... }: {
    networking.firewall.allowedTCPPorts = [ 8500 ];
    services.consul = {
      enable = true;
      extraConfig = {
        bind_addr = config.networking.primaryIPAddress;
        server = true;
        bootstrap_expect = 1;
      };
    };
  };
}
