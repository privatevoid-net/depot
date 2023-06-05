{ tools, ... }:

{
  services.meet = {
    nodes.host = [ "prophet" ];
    nixos.host = ./host.nix;
  };

  monitoring.blackbox.targets.jitsi-videobridge = {
    address = "meet.${tools.meta.domain}:7777";
    module = "tcpConnect";
  };
}
