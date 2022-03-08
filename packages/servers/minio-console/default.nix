{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "minio-console";
  version = "0.15.1";

  src = fetchFromGitHub {
    owner = "minio";
    repo = "console";
    rev = "v${version}";
    sha256 = "sha256-z+4DVJNV1P2/EGJG+tmZjNJiUAUjiH3ko51/9nuLs1c=";
  };

  vendorSha256 = "sha256-h1yIpn5XF7+UeSr1hZEUcKro634zrObvE1ies8yVeGE=";

  doCheck = false;
}
