{ config, lib, ... }:

{
  imports = [
    ./options
  ];

  services.ways = {
    nodes.host = config.services.websites.nodes.host;
    nixos.host = ./host.nix;
    simulacrum.deps = [ "nginx" "acme-client" "dns" "certificates" "consul" ];
  };

  dns.records = lib.mapAttrs'
    (_: cfg: lib.nameValuePair cfg.dnsRecord.name ({ ... }: {
      imports = [ cfg.dnsRecord.value ];
      root = cfg.domainSuffix;
    }))
    config.ways;
}
