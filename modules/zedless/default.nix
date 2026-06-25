{ config, lib, pkgs, ... }:

let
  configFormat = pkgs.formats.json { };
in

{
  imports = [
    ./lsp.nix
    ./editor.nix
    ./open-in-zedless.nix
    ./agent.nix
  ];

  options.programs.zedless = {
    settings = lib.mkOption {
      inherit (configFormat) type;
      default = { };
    };
  };

  config.systemd.user.services.zedless-config = {
    description = "Configure Zedless";
    wantedBy = [ "graphical-session.target" ];
    before = [ "graphical-session.target" ];

    script = let
      zedlessSettingsFile = "$HOME/.config/zedless/settings.json";
      settingsJson = pkgs.writeText "zedless-settings.json" (builtins.toJSON config.programs.zedless.settings);
    in ''
      if ! test -e "${zedlessSettingsFile}"; then
        echo '{}' > "${zedlessSettingsFile}"
      fi
      ${pkgs.hujsonfmt}/bin/hujsonfmt -s "${zedlessSettingsFile}" \
      | ${pkgs.jq}/bin/jq > "${zedlessSettingsFile}.tmp" \
        --slurpfile config ${settingsJson} \
        '. * $config[0]'
      mv "${zedlessSettingsFile}.tmp" "${zedlessSettingsFile}"
    '';
  };
}
