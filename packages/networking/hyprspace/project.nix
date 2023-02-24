{ lib, inputs, ... }:

{
  perSystem = { pkgs, ... }: {
    projectShells.hyprspace = {
      tools = [
        pkgs.go_1_18
      ];
      env.GOPATH.eval = "$REPO_DATA_DIR/go";
    };
    packages.hyprspace = with pkgs; buildGo118Module {
      pname = "hyprspace";
      version = "0.5.2";

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

      vendorSha256 = "sha256-Eg2tY5Zdn6g1OKrYDE7jQGuFtgrbPrz/3EPFK48K1Qk=";

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
