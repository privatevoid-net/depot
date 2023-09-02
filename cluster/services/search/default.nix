{ depot, ... }:

{
  services.search = {
    nodes.host = [ "VEGAS" ];
    nixos.host = ./host.nix;
  };

  monitoring.blackbox.targets.search = {
    address = "https://search.${depot.lib.meta.domain}/healthz";
    module = "https2xx";
  };
}
