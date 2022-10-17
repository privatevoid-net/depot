{ tools, ... }:

{
  vars = {
    ircServers = {
      VEGAS.subDomain = "eu1";
      prophet.subDomain = "eu2";
    };
    ircPeerKey = {
      file = ./irc-peer-key.age;
      owner = "ngircd";
      group = "ngircd";
    };
  };
  links = {
    irc = {
      ipv4 = "irc.${tools.meta.domain}";
      port = 6667;
    };
    ircSecure = {
      ipv4 = "irc.${tools.meta.domain}";
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
