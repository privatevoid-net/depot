{
  imports = [
    ./deploy.nix
    ./nixos.nix
    ./options
  ];
  gods = {
    fromLight = {
      checkmate = ./checkmate;

      thunderskin = ./thunderskin;

      VEGAS = ./VEGAS;

      prophet = ./prophet;

      grail = ./grail;

      thousandman = ./thousandman;
    };

    fromFlesh = {
      soda = ./soda;
    };

    fromNowhere = {
      # peering

      # max
      TITAN.hyprspace = {
        enable = true;
        id = "QmfJ5Tv2z9jFv9Aocevyn6QqRcfm9eYQZhvYvmAVfACfuM";
      };

      jericho.hyprspace = {
        enable = true;
        id = "QmccBLgGP3HR36tTkwSYZX3KDv2EXb1MvYwGVs6PbpbHv9";
      };
    };
  };
}
