{ cluster, config, depot, pkgs, ... }:
{
  users.motd = builtins.readFile ./motd.txt;
  environment.interactiveShellInit = let
    exec = package: program: "${package}/bin/${program}";
    util = exec pkgs.coreutils;
    uptime = exec pkgs.procps "uptime";
    grep = exec pkgs.gnugrep "grep";
    countUsers = '' ${util "who"} -q | ${util "head"} -n1 | ${util "tr"} ' ' \\n | ${util "uniq"} | ${util "wc"} -l'';
    countSessions = '' ${util "who"} -q | ${util "head"} -n1 | ${util "wc"} -w'';

    rev = if cluster.config.simulacrum then
      "simulacrum"
    else
      depot.rev or "\${BRED}(✘)\${CO}\${BWHITE} Dirty";
  in ''
    (
    # Reset colors
    CO='\033[0m'

    # Colors
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[0;37m'

    # Bold colors
    BBLACK='\033[1;30m'
    BRED='\033[1;31m'
    BGREEN='\033[1;32m'
    BYELLOW='\033[1;33m'
    BBLUE='\033[1;34m'
    BPURPLE='\033[1;35m'
    BCYAN='\033[1;36m'
    BWHITE='\033[1;37m'

    # Color accent to use in any primary text
    CA=$PURPLE
    CAB=$BPURPLE

    echo
    echo -e " █ ''${BGREEN}(✓)''${CO} ''${BWHITE}You are using a genuine Private Void™ system.''${CO}"
    echo    " █"
    echo -e " █ ''${BWHITE}OS Version....:''${CO} NixOS ''${CAB}${config.system.nixos.version}''${CO}" 
    echo -e " █ ''${BWHITE}Configuration.:''${CO} ''${CAB}${rev}''${CO}" 
    echo -e " █ ''${BWHITE}Uptime........:''${CO} $(${uptime} -p | ${util "cut"} -d ' ' -f2- | GREP_COLORS='mt=01;35' ${grep} --color=always '[0-9]*')"
    echo -e " █ ''${BWHITE}SSH Logins....:''${CO} There are currently ''${CAB}$(${countUsers})''${CO} users logged in on ''${CAB}$(${countSessions})''${CO} sessions"
    )
  '';
}
