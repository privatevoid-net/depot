{ depot, ... }:

{
  services.matrix = {
    nodes.homeserver = [ "VEGAS" ];
    nixos.homeserver = [
      ./homeserver.nix
      ./coturn.nix
      ./bridges/discord.nix
      ./federation.nix
      ./web-client.nix
    ];
  };

  monitoring.blackbox.targets.matrix = {
    address = "https://matrix.${depot.lib.meta.domain}/_matrix/federation/v1/version";
    module = "https2xx";
  };
}
