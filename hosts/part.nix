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

      thunderskin = import ./thunderskin tools;

      VEGAS = import ./VEGAS tools;

      prophet = import ./prophet tools;

      grail = import ./grail tools;
      
      thousandman = import ./thousandman tools;
    };

    fromFlesh = {
      soda = import ./soda tools;
    };

    fromNowhere = {
      # peering

      # max
      TITAN.hyprspace = {
        enable = true;
        id = "QmfJ5Tv2z9jFv9Aocevyn6QqRcfm9eYQZhvYvmAVfACfuM";
        # addr = "10.100.3.7";
      };

      jericho.hyprspace = {
        enable = true;
        id = "QmccBLgGP3HR36tTkwSYZX3KDv2EXb1MvYwGVs6PbpbHv9";
        # addr = "10.100.3.13";
      };
    };
  };
}
