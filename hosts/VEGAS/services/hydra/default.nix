{ pkgs, lib, config, tools, ... }:
let
  inherit (tools.meta) domain;
in
{
  age.secrets = {
    hydraS3 = {
      file = ../../../../secrets/hydra-s3.age;
      group = "hydra";
      mode = "0440";
    };
    hydra-bincache-key = {
      file = ../../../../secrets/hydra-bincache.age;
      group = "hydra";
      mode = "0440";
    };
    hydra-builder-key = {
      file = ../../../../secrets/hydra-builder-key.age;
      group = "hydra";
      mode = "0440";
    };
  } // lib.mapAttrs' (k: v: lib.nameValuePair "hydra-database-credentials-for-${k}" v)
  (lib.genAttrs [ "hydra-queue-runner" "hydra-www" "hydra" ]
    (x:
      {
        file = ../../../../secrets/hydra-db-credentials.age;
        group = "hydra";
        owner = x;
        mode = "0400";
      }
    )
  );

  reservePortsFor = [ "hydra" ];

  services.nginx.virtualHosts."hydra.${domain}" = tools.nginx.vhosts.proxy "http://127.0.0.1:${config.portsStr.hydra}";

  services.oauth2_proxy.nginx.virtualHosts = [ "hydra.${domain}" ];

  services.hydra = {
    enable = true;
    dbi = "dbi:Pg:dbname=hydra;host=127.0.0.1;user=hydra;";
    hydraURL = "https://hydra.${domain}";
    port = config.ports.hydra;
    notificationSender = "hydra@${domain}";
    buildMachinesFiles = [ "/etc/nix/hydra-machines" ];
    useSubstitutes = true;
    extraConfig = ''
      store_uri = s3://nix-store?scheme=https&endpoint=object-storage.${domain}&secret-key=${config.age.secrets.hydra-bincache-key.path}
      server_store_uri = https://cache.${domain}
    '';
    extraEnv = {
      AWS_SHARED_CREDENTIALS_FILE = config.age.secrets.hydraS3.path;
      PGPASSFILE = config.age.secrets."hydra-database-credentials-for-hydra".path;
    };
  };

  # override weird hydra module stuff

  systemd.services = { 
    hydra-send-stats = lib.mkForce {};
  } // lib.genAttrs [ "hydra-notify" "hydra-queue-runner" "hydra-server" ]
  (x: let
      name = if x == "hydra-server" then "hydra-www" else
             if x == "hydra-notify" then "hydra-queue-runner" else x;
    in {
      environment = {
        PGPASSFILE = lib.mkForce config.age.secrets."hydra-database-credentials-for-${name}".path;
      };
    }
  );

  nix.extraOptions = lib.mkForce ''
    allowed-uris = https://git.${domain}
    keep-outputs = true
    keep-derivations = true
  '';

  programs.ssh.knownHosts.git = {
    hostNames = [ "git.${domain}" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC0rChVEO9Qt7hr7vyiyOP7N45CjaxssFCZNOPCszEQi";
  };
}
