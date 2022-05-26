{ buildGoModule, fetchFromGitHub, lib, pins }:

buildGoModule rec {
  pname = "minio-console";
  version = builtins.substring 1 (-1) pins.minio-console.version;

  src = pins.minio-console;

  vendorSha256 = "sha256-h1yIpn5XF7+UeSr1hZEUcKro634zrObvE1ies8yVeGE=";

  doCheck = false;
}
