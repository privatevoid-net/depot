{ config, lib, tools, ... }:

let
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
      ipv4 = "${subDomains.${name}}.irc.${domain}";
      inherit (config.links.irc) port;
    };
    ircSecure = {
      ipv4 = "${subDomains.${name}}.irc.${domain}";
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
}
