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

  # peering

  # max
  TITAN.hypr = {
    id = "QmfJ5Tv2z9jFv9Aocevyn6QqRcfm9eYQZhvYvmAVfACfuM";
    addr = "10.100.3.7";
  };
  jericho.hypr = {
    id = "QmccBLgGP3HR36tTkwSYZX3KDv2EXb1MvYwGVs6PbpbHv9";
    addr = "10.100.3.13";
  };
}
