{ lib, inputs, ... }:

{
  perSystem = { pkgs, ... }: {
    projectShells.hyprspace = {
      tools = [
        pkgs.go_1_20
      ];
      env.GOPATH.eval = "$REPO_DATA_DIR/go";
    };
    packages.hyprspace = with pkgs; buildGo120Module {
      pname = "hyprspace";
      version = "0.6.4";

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
          "rpc"
          "tun"
        ]);
      };

      vendorSha256 = "sha256-qdwJk8Cvwa7J2o+JQccTF6cnoiEGiJG0Nji7myvYmRQ=";

      meta = with lib; {
        description = "A Lightweight VPN Built on top of Libp2p for Truly Distributed Networks.";
        homepage = "https://github.com/hyprspace/hyprspace";
        license = licenses.asl20;
        maintainers = with maintainers; [ yusdacra ];
        platforms = platforms.linux ++ platforms.darwin;
      };
    };
  };
}
