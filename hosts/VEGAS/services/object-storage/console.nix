{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "minio-console";
  version = "0.12.5";

  src = fetchFromGitHub {
    owner = "minio";
    repo = "console";
    rev = "v${version}";
    sha256 = "sha256-Lyji1V5K8n7NvIqDecbIp1iGPZM4E+XIvexppk5qOZI=";
  };

  vendorSha256 = "sha256-LhDrbkxOlSuYCboAwEZ1ePp2Dl6akxjMvCKFHfPInlU=";

  doCheck = false;
}
