{ pkgs, lib, config, ... }:
{
  age.secrets = {
    hydraS3 = {
      file = ../../secrets/hydra-s3.age;
      group = "hydra";
      mode = "0440";
    };
  } // lib.mapAttrs' (k: lib.nameValuePair "hydra-database-credentials-for-${k}")
  (lib.genAttrs [ "hydra-queue-runner" "hydra-www" "hydra" ]
    (x:
      {
        file = ../../secrets/hydra-db-credentials.age;
        group = "hydra";
        owner = x;
        mode = "0400";
      }
    )
  );

  services.hydra = {
    enable = true;
    dbi = "dbi:Pg:dbname=hydra;host=10.1.0.1;user=hydra;";
    hydraURL = "https://hydra.privatevoid.net";
    notificationSender = "hydra@privatevoid.net";
    buildMachinesFiles = [ "/etc/nix/hydra-machines" ];
    useSubstitutes = true;
    extraConfig = ''
      store_uri = s3://nix-store?scheme=https&endpoint=object-storage.privatevoid.net&secret-key=/etc/hydra/bincache.key
      server_store_uri = https://cache.privatevoid.net
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
    allowed-uris = https://git.privatevoid.net
    keep-outputs = true
    keep-derivations = true
  '';

  programs.ssh.knownHosts.git = {
    hostNames = [ "git" "git.services.privatevoid.net" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC0rChVEO9Qt7hr7vyiyOP7N45CjaxssFCZNOPCszEQi";
  };
}
