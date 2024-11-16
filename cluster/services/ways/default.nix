{ config, lib, ... }:

{
  imports = [
    ./options
    ./simulacrum/test-data.nix
  ];

  services.ways = {
    nodes.host = config.services.websites.nodes.host;
    nixos.host = ./host.nix;
    simulacrum = {
      enable = true;
      deps = [ "nginx" "acme-client" "dns" "certificates" "consul" ];
      settings = ./simulacrum/test.nix;
      availableNodes = lib.take 3 config.services.ways.nodes.host;
    };
  };

  dns.records = lib.mapAttrs'
    (_: cfg: lib.nameValuePair cfg.dnsRecord.name ({ ... }: {
      imports = [ cfg.dnsRecord.value ];
      root = cfg.domainSuffix;
    }))
    config.ways;
}
