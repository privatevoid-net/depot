{ pkgs, config, inputs, ... }:

let
  builder = {
    systems = [ "x86_64-linux" "i686-linux" ];
    speedFactor = 500;
    supportedFeatures = [ "benchmark" "nixos-test" ];
    sshKey = config.age.secrets.nixBuilderKey.path;
  };
  bigBuilder = builder // {
    speedFactor = 1000;
    supportedFeatures = builder.supportedFeatures ++ [ "kvm" "big-parallel" ];
  };
in {
  age.secrets.nixBuilderKey = {
    file = ../../secrets/builder_key.age;
    mode = "0400";
  };
  nixpkgs.overlays = [
    (self: super: {
      nixSuperUnstable = inputs.self.packages.x86_64-linux.nix-super-unstable;
    })
  ];
  nix = {
    package = pkgs.nixSuperUnstable;

    trustedUsers = [ "root" "@wheel" ];

    extraOptions = ''
      experimental-features = nix-command flakes ca-references
      warn-dirty = false
      builders-use-substitutes = true
      flake-registry = ${
        pkgs.writeText "null-registry.json" ''{"flakes":[],"version":2}''
      }
    '';

    binaryCaches = [ "https://cache.privatevoid.net" ];
    binaryCachePublicKeys = [ "cache.privatevoid.net:SErQ8bvNWANeAvtsOESUwVYr2VJynfuc9JRwlzTTkVg=" ];

    autoOptimiseStore = true;

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    distributedBuilds = true;

    buildMachines = [
      (bigBuilder // {
        sshUser = "root";
        hostName = "styx.services.private.void";
        speedFactor = 2000;
        maxJobs = 2;
      })
      (bigBuilder // {
        sshUser = "nix";
        hostName = "wired.titan.find.private.void";
        maxJobs = 12;
      })
      (bigBuilder // {
        sshUser = "nixbuilder";
        hostName = "animus.com";
        speedFactor = 3000;
        maxJobs = 4;
      })
    ];
  };
}
