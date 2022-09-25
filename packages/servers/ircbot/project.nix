{ inputs, pkgs, ... }:

let
  python = pkgs.python3;
  procfile = pkgs.writeText "Procfile" ''
    ircd: ${pkgs.ngircd}/bin/ngircd --config ${ircdConfig} --nodaemon
  '';

  ircdConfig = pkgs.writeText "ngircd.conf" ''
    [Global]
    Name = ircbot-dev.local
    Info = IRC Bot Development
    Network = IRCBotDev
    Listen = 127.0.0.1
    Ports = 6668

    [Options]
    Ident = no
    PAM = no
    AllowedChannelTypes = #
    OperCanUseMode = yes
    OperChanPAutoOp = yes

    [Channel]
    Name = #general
    Topic = General discussions

    [Operator]
    Name = op
    Password = op
  '';
in
{
  projectShells.ircbot = {
    commands = {
      irssi-dev = {
        help = "Irssi for development";
        command = "exec ${pkgs.irssi}/bin/irssi --config=$PRJ_DATA_DIR/irssi-config --home=$PRJ_DATA_DIR/irssi-home -c 127.0.0.1 -p 6668 \"$@\"";
      };
      svc = {
        help = "goreman with development services";
        command = "exec ${pkgs.goreman}/bin/goreman -f ${procfile} -set-ports=false \"$@\"";
      };
    };
    tools = [
      python
    ];
  };
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
