{ config, depot, lib, ... }:

let
  inherit (depot) hours;

  meshNet = rec {
    netAddr = "10.1.1.0";
    prefix = 24;
    cidr = "${netAddr}/${toString prefix}";
  };

  getExtAddr = host: host.interfaces.primary.addrPublic;
in
{
  vars = {
    mesh = lib.genAttrs config.services.wireguard.nodes.mesh (node: config.hostLinks.${node}.mesh.extra);
    inherit meshNet;
  };
  hostLinks = {
    checkmate.mesh = {
      ipv4 = getExtAddr hours.checkmate;
      extra = {
        meshIp = "10.1.1.32";
        inherit meshNet;
        pubKey = "fZMB9CDCWyBxPnsugo3Uxm/TIDP3VX54uFoaoC0bP3U=";
        extraRoutes = [];
      };
    };
    grail.mesh = {
      ipv4 = getExtAddr hours.grail;
      extra = {
        meshIp = "10.1.1.6";
        inherit meshNet;
        pubKey = "0WAiQGdWySsGWFUk+a9e0I+BDTKwTyWQdFT2d7BMfDQ=";
        extraRoutes = [];
      };
    };
    thunderskin.mesh = {
      ipv4 = getExtAddr hours.thunderskin;
      extra = {
        meshIp = "10.1.1.4";
        inherit meshNet;
        pubKey = "xvSsFvCVK8h2wThZJ7E5K0fniTBIEIYOblkKIf3Cwy0=";
        extraRoutes = [];
      };
    };
    VEGAS.mesh = {
      ipv4 = getExtAddr hours.VEGAS;
      extra = {
        meshIp = "10.1.1.5";
        inherit meshNet;
        pubKey = "NpeB8O4erGTas1pz6Pt7qtY9k45YV6tcZmvvA4qXoFk=";
        extraRoutes = [ "${hours.VEGAS.interfaces.vstub.addr}/32" "10.10.0.0/16" ];
      };
    };
    prophet.mesh = {
      ipv4 = getExtAddr hours.prophet;
      extra = {
        meshIp = "10.1.1.9";
        inherit meshNet;
        pubKey = "MMZAbRtNE+gsLm6DJy9VN/Y39E69oAZnvOcFZPUAVDc=";
        extraRoutes = [];
      };
    };
  };
  services.wireguard = {
    nodes = {
      mesh = [ "checkmate" "grail" "thunderskin" "VEGAS" "prophet" ];
      storm = [ "VEGAS" ];
    };
    nixos = {
      mesh = ./mesh.nix;
      storm = ./storm.nix;
    };
    secrets.meshPrivateKey = {
      nodes = config.services.wireguard.nodes.mesh;
      shared = false;
    };
  };
}
