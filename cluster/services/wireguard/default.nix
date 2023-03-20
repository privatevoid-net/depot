{ config, depot, ... }:

let
  inherit (depot.config) hours;

  meshNet = rec {
    netAddr = "10.1.1.0";
    prefix = 24;
    cidr = "${netAddr}/${toString prefix}";
  };

  getExtAddr = host: host.interfaces.primary.addrPublic;
in
{
  vars = {
    mesh = {
      checkmate = config.links.mesh-node-checkmate.extra;
      VEGAS = config.links.mesh-node-VEGAS.extra;
      prophet = config.links.mesh-node-prophet.extra;
    };
    inherit meshNet;
  };
  links = {
    mesh-node-checkmate = {
      ipv4 = getExtAddr hours.checkmate;
      extra = {
        meshIp = "10.1.1.32";
        inherit meshNet;
        pubKey = "fZMB9CDCWyBxPnsugo3Uxm/TIDP3VX54uFoaoC0bP3U=";
        privKeyFile = ./mesh-keys/checkmate.age;
        extraRoutes = [];
      };
    };
    mesh-node-thunderskin = {
      ipv4 = getExtAddr hours.thunderskin;
      extra = {
        meshIp = "10.1.1.4";
        inherit meshNet;
        pubKey = "xvSsFvCVK8h2wThZJ7E5K0fniTBIEIYOblkKIf3Cwy0=";
        privKeyFile = ./mesh-keys/thunderskin.age;
        extraRoutes = [];
      };
    };
    mesh-node-VEGAS = {
      ipv4 = getExtAddr hours.VEGAS;
      extra = {
        meshIp = "10.1.1.5";
        inherit meshNet;
        pubKey = "NpeB8O4erGTas1pz6Pt7qtY9k45YV6tcZmvvA4qXoFk=";
        privKeyFile = ./mesh-keys/VEGAS.age;
        extraRoutes = [ "${hours.VEGAS.interfaces.vstub.addr}/32" "10.10.0.0/16" ];
      };
    };
    mesh-node-prophet = {
      ipv4 = getExtAddr hours.prophet;
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
      mesh = [ "checkmate" "thunderskin" "VEGAS" "prophet" ];
    };
    nixos = {
      mesh = ./mesh.nix;
    };
  };
}
