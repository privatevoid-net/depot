{ buildGo117Module, lib, pins }:

buildGo117Module rec {
  pname = "minio-console";
  version = builtins.substring 1 (-1) pins.minio-console.version;

  src = pins.minio-console;

  vendorSha256 = "sha256-tBh6N1Vn8RpAw0pY55isf1/50JfxBn29SFLtJdXcsQU=";

  doCheck = false;

  subPackages = [ "cmd/console" ];
}
