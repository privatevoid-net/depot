{ config, depot, lib, ... }:

let
  inherit (depot) hours;

  inherit (depot.lib.meta) domain;

  subDomains = {
    grail = "eu1";
    prophet = "eu2";
  };
in
{
  vars = {
    ircOpers = [ "max" "num" "ark" ];
  };
  hostLinks = lib.genAttrs config.services.irc.nodes.host (name: {
    irc = {
      hostname = "${subDomains.${name}}.irc.${domain}";
      ipv4 = hours.${name}.interfaces.primary.addrPublic;
      inherit (config.links.irc) port;
    };
    ircSecure = {
      hostname = "${subDomains.${name}}.irc.${domain}";
      ipv4 = hours.${name}.interfaces.primary.addrPublic;
      inherit (config.links.ircSecure) port;
    };
  });
  links = {
    irc = {
      ipv4 = "irc.${domain}";
      port = 6667;
    };
    ircSecure = {
      ipv4 = "irc.${domain}";
      port = 6697;
    };
  };
  services.irc = {
    nodes = {
      host = [ "grail" "prophet" ];
    };
    nixos = {
      host = [
        ./irc-host.nix
      ];
    };
    secrets.peerKey = {
      nodes = config.services.irc.nodes.host;
      owner = "ngircd";
      services = [ "ngircd" ];
    };
  };

  monitoring.blackbox.targets = {
    irc = {
      address = config.links.ircSecure.tuple;
      module = "ircsConnect";
    };
  };

  dns.records.irc.consulService = "irc";
}
