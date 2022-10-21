{ inputs, lib, pkgs, ... }:

{
  projectShells.ipfs-cluster = {
    tools = [
      pkgs.go_1_18
      pkgs.gnumake
      pkgs.gcc
    ];
    env.GOPATH.eval = "$PRJ_DATA_DIR/go";
  };
  packages.ipfs-cluster = with pkgs; buildGo118Module {
    pname = "ipfs-cluster";
    version = "1.0.2";

    src = with inputs.nix-filter.lib; filter {
      root = ./.;
      include = [
        "go.mod"
        "go.sum"
        (matchExt "go")
      ] ++ (map inDirectory [
        "adder"
        "allocator"
        "api"
        "cmd"
        "cmdutils"
        "config"
        "consensus"
        "datastore"
        "docker"
        "informer"
        "ipfsconn"
        "monitor"
        "observations"
        "pintracker"
        "pstoremgr"
        "rpcutil"
        "sharness"
        "state"
        "test"
        "version"
      ]);
    };

    vendorSha256 = "sha256-/fy46kF9XN0nrkmgPjFCxHGsqbxabTKFNGKUIoDBDjI=";

    doCheck = false;

    meta = with lib; { 
      description = "Allocate, replicate, and track Pins across a cluster of IPFS daemons"; 
      homepage = "https://ipfscluster.io"; 
      license = licenses.mit; 
      platforms = platforms.unix; 
      maintainers = with maintainers; [ Luflosi jglukasik ]; 
    }; 
  };
}
