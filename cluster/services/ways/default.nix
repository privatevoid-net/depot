{ config, lib, ... }:

{
  imports = [
    ./options
    ./simulacrum/test-data.nix
  ];

  services.ways = {
    nodes.host = [ "VEGAS" "prophet" ];
    nixos.host = ./host.nix;
    simulacrum = {
      enable = true;
      deps = [ "nginx" "acme-client" "dns" "certificates" "consul" ];
      settings = ./simulacrum/test.nix;
    };
  };

  dns.records = lib.mapAttrs'
    (_: cfg: lib.nameValuePair cfg.fqdn ({ ... }: {
      inherit (cfg.dnsRecord) name;
      imports = [ cfg.dnsRecord.value ];
    }))
    config.ways;
}
