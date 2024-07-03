{ config, lib, ... }:

{
  imports = [
    ./options
  ];

  services.ways = {
    nodes.host = config.services.websites.nodes.host;
    nixos.host = ./host.nix;
  };

  dns.records = lib.mapAttrs (name: cfg: {
    consulService = "${name}.ways-proxy";
  }) (lib.filterAttrs (_: cfg: !cfg.internal) config.ways);
}
