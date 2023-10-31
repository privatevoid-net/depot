{
  services.attic = {
    nodes = {
      server = [ "VEGAS" ];
    };
    nixos = {
      server = [
        ./server.nix
        ./binary-cache.nix
        ./nar-serve.nix
      ];
    };
  };

  garage = {
    keys.attic = { };
    buckets.attic = {
      allow.attic = [ "read" "write" ];
    };
  };
}
