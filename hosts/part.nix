let
  tools = import ./tools.nix;
in with tools.dns;
{
  imports = [
    ./deploy.nix
    ./nixos.nix
    ./options
  ];
  gods = {
    fromLight = {
      checkmate = import ./checkmate tools;

      VEGAS = import ./VEGAS tools;

      prophet = import ./prophet tools;
    };

    fromFlesh = {
      soda = import ./soda tools;
    };

    fromNowhere = {
      AnimusAlpha = let hostNames = [ "alpha.animus.com" "animus.com" ]; in {
        ssh.enable = true;
        ssh.id = {
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGpFR47Ev+W+bdng6IrDVpl8rlKBBHSr1v5lwJmZcEFH";
          hostNames = portMap 69 hostNames;
        };
        ssh.extraConfig = tools.ssh.extraConfig hostNames [ "Port 69" ];
      };

      # peering

      # max
      TITAN.hyprspace = {
        enable = true;
        id = "QmfJ5Tv2z9jFv9Aocevyn6QqRcfm9eYQZhvYvmAVfACfuM";
        addr = "10.100.3.7";
      };

      jericho.hyprspace = {
        enable = true;
        id = "QmccBLgGP3HR36tTkwSYZX3KDv2EXb1MvYwGVs6PbpbHv9";
        addr = "10.100.3.13";
      };
    };
  };
}
