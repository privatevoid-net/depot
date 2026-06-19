{ pkgs, ... }:

let
  # tricks xdg-document-portal into not using the document portal for pointless things
  # note that we report read-write even if the access is supposed to be read-only,
  # because ticking the checkbox in the dialog every time is annoying, ro status
  # is enforced by the sandbox anyway
  # example call: flatpak info --file-access=/srv/file.txt com.nixpak.Whatever
  documentPortalFileAccessTrick = pkgs.writeShellScriptBin "flatpak" ''
    [[ "$1" == "info" ]] || exit 1
    case "$3" in
      org.chromium.Chromium)
        case "''${2#--file-access=}" in
          $HOME/Downloads*) echo read-write;;
          *) echo hidden;;
        esac;;
      io.bassi.Amberol)
        case "''${2#--file-access=}" in
          $HOME/Music*) echo read-write;;
          /srv/data/music*) echo read-write;;
          *) echo hidden;;
        esac;;
      *)
        echo hidden;;
    esac
  '';
in
{
  environment.systemPackages = [
    documentPortalFileAccessTrick
  ];
}
