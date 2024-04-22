{ lib, inputs, ... }:

{
  perSystem = { pkgs, ... }: {
    projectShells.hyprspace = {
      tools = [
        pkgs.go_1_20
      ];
      env.GOPATH.eval = "$REPO_DATA_DIR/go";
    };
    packages.hyprspace = with pkgs; buildGo120Module rec {
      pname = "hyprspace";
      version = "0.8.5";

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
          "dns"
          "p2p"
          "rpc"
          "tun"
        ]);
      };

      vendorHash = "sha256-VBCgFbJixBh+pKfYGJVapHqWBpUFfvjl1cwOER2Li6Y=";

      ldflags = [ "-s" "-w" "-X github.com/hyprspace/hyprspace/cli.appVersion=${version}" ];

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
