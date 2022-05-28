{
  environment.interactiveShellInit = ''
    source ${./insults.sh}
    source ${./motd.sh}
    source ${./soda-prompt.sh}
  '';
}