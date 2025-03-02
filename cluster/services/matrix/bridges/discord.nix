{ cluster, config, depot, lib, pkgs, ... }:
let
  inherit (depot.lib.meta) domain;
  inherit (depot.packages) out-of-your-element;
  inherit (cluster.config.services.matrix) secrets;
  secretFile = config.age.secrets.cluster-matrix-discordBridgeToken.file;
  synapse = config.services.matrix-synapse;
  synapseService = config.systemd.services.matrix-synapse.serviceConfig;
  stateDir = "${synapse.dataDir}/out-of-your-element";
  link = config.links.outOfYourElement;

  registration = {
    id = "ooye";
    namespaces = {
      users = lib.singleton {
        exclusive = true;
        regex = "@_ooye_.*:${lib.escapeRegex domain}";
      };
      aliases = lib.singleton {
        exclusive = true;
        regex = "#_ooye_.*:${lib.escapeRegex domain}";
      };
    };
    protocols = [ "discord" ];
    sender_localpart = "_ooye_bot";
    rate_limited = false;
    socket = link.port;
    inherit (link) url;
    ooye = {
      namespace_prefix = "_ooye_";
      server_name = domain;
      server_origin = "https://matrix.${domain}:443";
      bridge_origin = "https://discord.bridges.matrix.${domain}";
      max_file_size = 5000000;
      content_length_workaround = false;
      include_user_id_in_mxid = false;
      invite = [];
    };
  };
  registrationJson = pkgs.writeText "out-of-your-element-registration.json" (builtins.toJSON registration);
  registrationOut = "${stateDir}/registration.yaml";
in
{
  links.outOfYourElement = {
    protocol = "http";
    port = 6693; # partially hardcoded in the package
  };
  systemd.tmpfiles.settings.matrix-bridges."${stateDir}".d = {
    mode = "0700";
    user = synapseService.User;
    group = synapseService.Group;
  };
  systemd.services = {
    ooye-init = {
      description = "Out Of Your Element Setup";
      before = [ synapse.serviceUnit ];
      wantedBy = [ synapse.serviceUnit ];
      serviceConfig = {
        inherit (synapseService) User Group;
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = stateDir;
        ExecStart = "${out-of-your-element}/bin/out-of-your-element-setup";
      };
      restartTriggers = [ secretFile ];
      preStart = let
        genSecret = "head -c1024 /dev/urandom | sha256sum | head -c64";
      in ''
        if ! test -e secrets.json; then
          ${pkgs.jq}/bin/jq -c -n '{
            as_token: $asToken,
            hs_token: $hsToken
          }' --rawfile asToken <(${genSecret}) --rawfile hsToken <(${genSecret}) | install -m400 /dev/stdin secrets.json
        fi
        ${pkgs.jq}/bin/jq -c --slurp '.[0] * .[1] * .[2]' ${registrationJson} secrets.json '${secrets.discordBridgeToken.path}' > '${registrationOut}'
      '';
    };
    ooye = {
      description = "Out Of Your Element";
      after = [ "ooye-init.service" synapse.serviceUnit ];
      requires = [ "ooye-init.service" synapse.serviceUnit ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        inherit (synapseService) User Group;
        WorkingDirectory = stateDir;
        ExecStart = "${out-of-your-element}/bin/out-of-your-element";
      };
      restartTriggers = [ registrationJson secretFile ];
    };
  };
  services.matrix-synapse.settings = {
    app_service_config_files =  [ registrationOut ];
  };
  services.nginx.virtualHosts."discord.bridges.matrix.${domain}" = depot.lib.nginx.vhosts.proxy link.url;
}
