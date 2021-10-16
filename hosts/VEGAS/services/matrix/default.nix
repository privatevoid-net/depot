{ config, lib, pkgs, tools, ... }:
let
  inherit (tools.meta) domain;
  listener = {
    port = 8008;
    bind_address = "127.0.0.1";
    type = "http";
    tls = false;
    x_forwarded = true;
    resources = lib.singleton {
      names = [ "client" "federation" ];
      compress = false;
    };
  };
  clientConfig = {
    "m.homeserver".base_url = "https://matrix.${domain}:443";
    "m.integrations".managers = [{
      api_url = "https://dimension.t2bot.io/api/v1/scalar";
      ui_url = "https://dimension.t2bot.io/riot";
    }];
  } // lib.optionalAttrs config.services.jitsi-meet.enable {
    "im.vector.riot.jitsi".preferredDomain = config.services.jitsi-meet.hostName;
  };
  clientConfigJSON = pkgs.writeText "matrix-client-config.json" (builtins.toJSON clientConfig);
  extraConfig = {
    experimental_features.spaces_enabled = true;
    federation_ip_range_blacklist = cfg.url_preview_ip_range_blacklist;
    admin_contact = "mailto:admins@${domain}";
    max_upload_size = "32M";
    max_spider_size = "10M";
    emable_registration = true;
    allow_guest_access = true;
    push.include_content = true;
    group_creation_prefix = "unofficial/";
    app_service_config_files =  [
      "/etc/synapse/discord-registration.yaml"
    ];
    turn_uris = let
      combinations = lib.cartesianProductOfSets {
        proto = [ "udp" "tcp" ];
        scheme = [ "turns" "turn" ];
      };
      makeTurnServer = x: "${x.scheme}:turn.${domain}?transport=${x.proto}";
    in map makeTurnServer combinations;
  };
  cfg = config.services.matrix-synapse;
in {
  imports = [
    ./bridges/discord.nix
    ./federation.nix
    ./web-client.nix
  ];

  age.secrets = {
    synapse-ldap = {
      file = ../../../../secrets/synapse-ldap.age;
      owner = "matrix-synapse";
      group = "matrix-synapse";
      mode = "0400";
    };
    synapse-db = {
      file = ../../../../secrets/synapse-db.age;
      owner = "matrix-synapse";
      group = "matrix-synapse";
      mode = "0400";
    };
    synapse-turn = {
      file = ../../../../secrets/synapse-turn.age;
      owner = "matrix-synapse";
      group = "matrix-synapse";
      mode = "0400";
    };
    synapse-keys = {
      file = ../../../../secrets/synapse-keys.age;
      owner = "matrix-synapse";
      group = "matrix-synapse";
      mode = "0400";
    };
  };
  services.matrix-synapse = {
    enable = true;
    plugins = [ pkgs.matrix-synapse-plugins.matrix-synapse-ldap3 ];

    server_name = domain;
    listeners = lib.singleton listener;

    url_preview_enabled = true;

    extraConfigFiles = [
      (pkgs.writeText "synapse-extra-config.yaml" (builtins.toJSON extraConfig))
    ] ++ (map (x: config.age.secrets.${x}.path) [
      "synapse-ldap"
      "synapse-db"
      "synapse-turn"
      "synapse-keys"
    ]); 
  };

  services.nginx.virtualHosts = tools.nginx.mappers.mapSubdomains {
    matrix = tools.nginx.vhosts.basic // {
      locations."/".return = "204";
      locations."/_matrix" = {
        proxyPass = with listener; "${type}://${bind_address}:${builtins.toString port}";
        extraConfig = "client_max_body_size ${extraConfig.max_upload_size};";
      };
      locations."= /.well-known/matrix/client".alias = clientConfigJSON;
    };
  };
}
