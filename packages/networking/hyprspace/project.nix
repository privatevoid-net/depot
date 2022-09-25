{ inputs, lib, pkgs, ... }:

{
  projectShells.hyprspace = {
    tools = [
      pkgs.go
    ];
    env.GOPATH.eval = "$PRJ_DATA_DIR/go";
  };
  packages.hyprspace = with pkgs; buildGoModule {
    pname = "hyprspace";
    version = "0.2.2";

    src = with inputs.nix-filter.lib; let
      dirs = map inDirectory;
    in filter {
      root = ./.;
      include = [
        "go.mod"
        "go.sum"
        (matchExt "go")
      ] ++ (dirs [
        "cli"
        "config"
        "p2p"
        "tun"
      ]);
    };

    vendorSha256 = "sha256-8j9M8LrcqiPShCCNOmmJoY6wclHRiX2xOJH/wvlwvwY=";

    meta = with lib; {
      description = "A Lightweight VPN Built on top of Libp2p for Truly Distributed Networks.";
      homepage = "https://github.com/hyprspace/hyprspace";
      license = licenses.asl20;
      maintainers = with maintainers; [ yusdacra ];
      platforms = platforms.linux ++ platforms.darwin;
    };
  };
}
