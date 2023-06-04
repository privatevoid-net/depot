{ config, depot, lib, tools, ... }:

let
  inherit (depot.config) hours;

  inherit (tools.meta) domain;

  subDomains = {
    VEGAS = "eu1";
    prophet = "eu2";
  };
in
{
  vars = {
    ircPeerKey = {
      file = ./irc-peer-key.age;
      owner = "ngircd";
      group = "ngircd";
    };
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
      host = [ "VEGAS" "prophet" ];
    };
    nixos = {
      host = [
        ./irc-host.nix
      ];
    };
  };

  monitoring.blackbox.targets = {
    irc = {
      address = "irc.${domain}";
      module = "ircsConnect";
    };
  };
}
