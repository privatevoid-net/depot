{ config, depot, ... }:

let
  inherit (depot.lib.meta) domain;
in

{
  services.matrix = {
    nodes = {
      homeserver = [ "thousandman" ];
    };
    nixos = {
      homeserver = [
        ./homeserver.nix
        ./bridges/discord.nix
      ];
    };
    secrets = let
      inherit (config.services.matrix) nodes;
      default = {
        nodes = nodes.homeserver;
        owner = "matrix-synapse";
      };
    in {
      ldapConfig = default;
      keysConfig = default;
      discordBridgeToken = {
        nodes = nodes.homeserver;
        owner = "matrix-synapse";
      };
    };
  };

  monitoring.blackbox.targets.matrix = {
    address = "https://matrix.${domain}/_matrix/federation/v1/version";
    module = "https2xx";
  };

  garage = config.lib.forService "matrix" {
    keys.synapse.locksmith = {
      nodes = config.services.matrix.nodes.homeserver;
      owner = "matrix-synapse";
    };
    buckets.matrix-media.allow.synapse = [ "read" "write" ];
  };

  dns.records = let
    homeserverAddrs = map
      (node: depot.hours.${node}.interfaces.primary.addrPublic)
      config.services.matrix.nodes.homeserver;
  in {
    matrix.target = homeserverAddrs;
    stun.target = homeserverAddrs;
    turn.target = homeserverAddrs;
    "discord.bridges.matrix".target = homeserverAddrs;
  };

  ways = config.lib.forService "matrix" {
    chat = {
      static = { depot', ... }: depot'.packages.cinny.webroot;
      staticLocations."= /config.json" = { pkgs, ... }: pkgs.writeText "cinny-config.json" (builtins.toJSON {
        defaultHomeserver = 0;
        homeserverList = [ domain ];
        allowCustomHomeservers = false;
      });
      extras.locations."/".extraConfig = ''
        rewrite ^/config.json$ /config.json break;
        rewrite ^/manifest.json$ /manifest.json break;

        rewrite ^.*/olm.wasm$ /olm.wasm break;
        rewrite ^/pdf.worker.min.js$ /pdf.worker.min.js break;

        rewrite ^/public/(.*)$ /public/$1 break;
        rewrite ^/assets/(.*)$ /assets/$1 break;

        rewrite ^(.+)$ /index.html break;
      '';
    };
    top-level = {
      staticLocations."= /.well-known/matrix/server" = { pkgs, ... }: pkgs.writeText "matrix-federation.json" (builtins.toJSON {
        "m.server" = "matrix.${domain}:443";
      });
      extras.locations = let
        extraConfig = ''
          add_header X-Content-Type-Options "";
          add_header Access-Control-Allow-Origin *;
        '';
      in {
        "= /.well-known/matrix/client" = {
          return = "302 https://matrix.${domain}/.well-known/matrix/client";
          inherit extraConfig;
        };
        "= /.well-known/matrix/server" = {
          inherit extraConfig;
        };
      };
    };
  };
}
