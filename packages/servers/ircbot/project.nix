{ inputs, pkgs, ... }:

let
  python = pkgs.python3;
in
{
  packages.ircbot = with pkgs; stdenvNoCC.mkDerivation {
    pname = "ircbot";
    version = "0.0.0";

    src = with inputs.nix-filter.lib; filter {
      root = ./.;
      include = [
        (matchExt "py")
        (inDirectory "hooks")
      ];
    };
    installPhase = ''
      mkdir -p $out/bin $out/lib

      cp -r $src/ $out/lib/ircbot

      cat <<EOF >$out/bin/ircbot
      #!${runtimeShell}
      export PYTHONNOUSERSITE=true
      export PYTHONPATH="$out/lib/ircbot"
      exec ${python.interpreter} $out/lib/ircbot/main.py "$@"
      EOF
      chmod +x $out/bin/ircbot
    '';
  };
}
