{ config, pkgs, depot, ... }:

let
  toml = pkgs.formats.toml {};
  atticConfig = toml.generate "attic-upload-config.toml" {
    default-server = "cache";
    servers.cache = {
      endpoint = "https://cache-api.privatevoid.net";
      token = "@atticToken@";
    };
  };
in

{
  services.locksmith.waitForSecrets.attic-upload = [ "attic-uploadToken" ];

  systemd.services.attic-upload = {
    description = "Attic Uploader";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ config.nix.package ];
    environment.XDG_CONFIG_HOME = "/run/attic-upload";
    preStart = ''
      install -dm700 "$XDG_CONFIG_HOME/attic"
      cp --no-preserve=mode ${atticConfig} "$XDG_CONFIG_HOME/attic/config.toml"
      ${pkgs.replace-secret}/bin/replace-secret '@atticToken@' "$CREDENTIALS_DIRECTORY/uploadToken" "$XDG_CONFIG_HOME/attic/config.toml"
    '';
    serviceConfig = {
      ExecStart = "${pkgs.attic-client}/bin/attic watch-store nix-store";
      Restart = "always";
      RestartSec = "30s";
      DynamicUser = true;
      RuntimeDirectory = "attic-upload";
      LoadCredential = [ "uploadToken:/run/locksmith/attic-uploadToken" ];
    };
  };
}
