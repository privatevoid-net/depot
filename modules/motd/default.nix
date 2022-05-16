{ config, inputs, pkgs, ... }:
{
  users.motd = builtins.readFile ./motd.txt;
  environment.interactiveShellInit = ''
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
    echo -e " █ ''${BWHITE}Configuration.:''${CO} ''${CAB}${inputs.self.rev or "\${BRED}(✘)\${CO}\${BWHITE} Dirty"}''${CO}" 
    echo -e " █ ''${BWHITE}Uptime........:''${CO} ''${CAB}$(${pkgs.procps}/bin/uptime -p | cut -d ' ' -f2-)''${CO}"
    echo -e " █ ''${BWHITE}SSH Logins....:''${CO} There are currently ''${CAB}$(${pkgs.coreutils}/bin/who | ${pkgs.coreutils}/bin/wc -l)''${CO} users logged in"
    )
  '';
}
