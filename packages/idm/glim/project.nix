{ inputs, lib, pkgs, ... }:

{
  projectShells.glim = {
    tools = [
      pkgs.go_1_18
    ];
    env.GOPATH.eval = "$PRJ_DATA_DIR/go";
  };
  packages.glim = with pkgs; buildGo118Module {
    pname = "glim";
    version = "0.4.0";

    src = with inputs.nix-filter.lib; let
      dirs = map inDirectory;
    in filter {
      root = ./.;
      include = [
        "go.mod"
        "go.sum"
        (matchExt "go")
      ] ++ (dirs [
        "cmd"
        "docs"
        "models"
        "server"
        "types"
      ]);
    };

    vendorSha256 = "sha256-y5wrZtzZAwq42GxI78mNII4+ZjgBt+CxeSkzSh453JQ=";

    meta = with lib; {
      description = "Glim is a simple identity access management system that speaks some LDAP and has a REST API to manage users and groups";
      homepage = "https://github.com/doncicuto/glim";
      license = licenses.asl20;
      platforms = platforms.linux;
    };
  };
}
