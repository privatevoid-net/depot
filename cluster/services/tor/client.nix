{ config, ... }:

{
  links.torSocks.protocol = "socks5h";

  services.tor = {
    enable = true;
    client = {
      enable = true;
      socksListenAddress = {
        IsolateDestAddr = true;
        addr = config.links.torSocks.ipv4;
        port = config.links.torSocks.port;
      };
    };
  };
}
