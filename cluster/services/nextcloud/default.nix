{ tools, ... }:

{
  services.nextcloud = {
    nodes.host = [ "VEGAS" ];
    nixos.host = ./host.nix;
  };

  monitoring.blackbox.targets.nextcloud = {
    address = "https://storage.${tools.meta.domain}/status.php";
    module = "nextcloudStatus";
  };
}
