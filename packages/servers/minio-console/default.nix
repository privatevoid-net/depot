{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "minio-console";
  version = "0.13.2";

  src = fetchFromGitHub {
    owner = "minio";
    repo = "console";
    rev = "v${version}";
    sha256 = "sha256-Ku1k0bm2CIpUVyA7GWCDS76kAukITk1F561wG/cPVxc=";
  };

  vendorSha256 = "sha256-7YPTNzYq9xz+yYIy6ItBgRicBlENLJk2HDRXfVZ74z8=";

  doCheck = false;
}
