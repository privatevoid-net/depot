{ config, ... }:

let
  inherit (config.vars) hosts;

  meshNet = rec {
    netAddr = "10.1.1.0";
    prefix = 24;
    cidr = "${netAddr}/${toString prefix}";
  };

  getExtAddr = host: host.interfaces.primary.addrPublic or host.interfaces.primary.addr;
in
{
  vars = {
    mesh = {
      VEGAS = config.links.mesh-node-VEGAS.extra;
      prophet = config.links.mesh-node-prophet.extra;
    };
    inherit meshNet;
  };
  links = {
    mesh-node-VEGAS = {
      ipv4 = getExtAddr hosts.VEGAS;
      extra = {
        meshIp = "10.1.1.5";
        inherit meshNet;
        pubKey = "NpeB8O4erGTas1pz6Pt7qtY9k45YV6tcZmvvA4qXoFk=";
        privKeyFile = ./mesh-keys/VEGAS.age;
        extraRoutes = [ "${hosts.VEGAS.interfaces.vstub.addr}/32" "10.10.0.0/16" ];
      };
    };
    mesh-node-prophet = {
      ipv4 = getExtAddr hosts.prophet;
      extra = {
        meshIp = "10.1.1.9";
        inherit meshNet;
        pubKey = "MMZAbRtNE+gsLm6DJy9VN/Y39E69oAZnvOcFZPUAVDc=";
        privKeyFile = ./mesh-keys/prophet.age;
        extraRoutes = [];
      };
    };
  };
  services.wireguard = {
    nodes = {
      mesh = [ "VEGAS" "prophet" ];
    };
    nixos = {
      mesh = ./mesh.nix;
    };
  };
}
