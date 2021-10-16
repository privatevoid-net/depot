let
  tools = import ./tools.nix;
in with tools.dns; {

  # NixOS machines
  styx = import ./styx tools;
  meet = import ./meet tools;
  git = import ./git tools;
  VEGAS = import ./VEGAS tools;

  # Non-NixOS machine metadata
  AnimusAlpha = let hostNames = [ "alpha.animus.com" "animus.com" ]; in {
    ssh.id = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGpFR47Ev+W+bdng6IrDVpl8rlKBBHSr1v5lwJmZcEFH";
      hostNames = portMap 69 hostNames;
    };
    ssh.extraConfig = tools.ssh.extraConfig hostNames [ "Port 69" ];
  };
}
