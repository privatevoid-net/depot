{ config, lib, pkgs, ... }:

let
  configFormat = pkgs.formats.json { };
in

{
  imports = [
    ./lsp.nix
    ./editor.nix
    ./open-in-gram.nix
  ];

  options.programs.gram = {
    settings = lib.mkOption {
      inherit (configFormat) type;
      default = { };
    };
  };

  config.systemd.user.services.gram = {
    description = "Configure Gram";
    wantedBy = [ "graphical-session.target" ];
    before = [ "graphical-session.target" ];

    script = let
      gramSettingsFile = "$HOME/.config/gram/settings.json";
      settingsJson = pkgs.writeText "gram-settings.json" (builtins.toJSON config.programs.gram.settings);
    in ''
      if ! test -e "${gramSettingsFile}"; then
        echo '{}' > "${gramSettingsFile}"
      fi
      ${pkgs.hujsonfmt}/bin/hujsonfmt -s "${gramSettingsFile}" \
      | ${pkgs.jq}/bin/jq > "${gramSettingsFile}.tmp" \
        --slurpfile config ${settingsJson} \
        '. * $config[0]'
      mv "${gramSettingsFile}.tmp" "${gramSettingsFile}"
    '';
  };
}
