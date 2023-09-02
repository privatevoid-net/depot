{
  lib.timeTravel = rev: builtins.getFlake "github:privatevoid-net/depot/${rev}";
}
