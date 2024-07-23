{ config, depot, lib, ... }:

let
  inherit (depot) hours;

  meshNet = rec {
    netAddr = "10.1.1.0";
    prefix = 24;
    cidr = "${netAddr}/${toString prefix}";
  };

  getExtAddr = host: host.interfaces.primary.addrPublic;

  snakeoilPublicKeys = {
    checkmate = "TESTtbFybW5YREwtd18a1A4StS4YAIUS5/M1Lv0jHjA=";
    grail = "TEsTh7bthkaDh9A1CpqDi/F121ao5lRZqIJznLH8mB4=";
    thunderskin = "tEST6afFmVN18o+EiWNFx+ax3MJwdQIeNfJSGEpffXw=";
    VEGAS = "tEsT6s7VtM5C20eJBaq6UlQydAha8ATlmrTRe9T5jnM=";
    prophet = "TEstYyb5IoqSL53HbSQwMhTaR16sxcWcMmXIBPd+1gE=";
  };

  grease = hourName: realPublicKey: if config.simulacrum then
    snakeoilPublicKeys.${hourName}
  else
    realPublicKey;
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
        pubKey = grease "checkmate" "fZMB9CDCWyBxPnsugo3Uxm/TIDP3VX54uFoaoC0bP3U=";
        extraRoutes = [];
      };
    };
    grail.mesh = {
      ipv4 = getExtAddr hours.grail;
      extra = {
        meshIp = "10.1.1.6";
        inherit meshNet;
        pubKey = grease "grail" "0WAiQGdWySsGWFUk+a9e0I+BDTKwTyWQdFT2d7BMfDQ=";
        extraRoutes = [];
      };
    };
    thunderskin.mesh = {
      ipv4 = getExtAddr hours.thunderskin;
      extra = {
        meshIp = "10.1.1.4";
        inherit meshNet;
        pubKey = grease "thunderskin" "xvSsFvCVK8h2wThZJ7E5K0fniTBIEIYOblkKIf3Cwy0=";
        extraRoutes = [];
      };
    };
    VEGAS.mesh = {
      ipv4 = getExtAddr hours.VEGAS;
      extra = {
        meshIp = "10.1.1.5";
        inherit meshNet;
        pubKey = grease "VEGAS" "NpeB8O4erGTas1pz6Pt7qtY9k45YV6tcZmvvA4qXoFk=";
        extraRoutes = [ "${hours.VEGAS.interfaces.vstub.addr}/32" "10.10.0.0/16" ];
      };
    };
    prophet.mesh = {
      ipv4 = getExtAddr hours.prophet;
      extra = {
        meshIp = "10.1.1.9";
        inherit meshNet;
        pubKey = grease "prophet" "MMZAbRtNE+gsLm6DJy9VN/Y39E69oAZnvOcFZPUAVDc=";
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
      mesh = [
        ./mesh.nix
      ] ++ lib.optionals config.simulacrum [
        ./simulacrum/snakeoil-keys.nix
      ];
      storm = [ ./storm.nix ];
    };
    secrets.meshPrivateKey = {
      nodes = config.services.wireguard.nodes.mesh;
      shared = false;
    };
  };
}
