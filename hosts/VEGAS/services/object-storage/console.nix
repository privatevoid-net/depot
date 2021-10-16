{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "minio-console";
  version = "0.10.1";

  src = fetchFromGitHub {
    owner = "minio";
    repo = "console";
    rev = "v${version}";
    sha256 = "sha256-exzWR5c0u4B+VF54Bp1mLoFOH/N+QnAUoIF2SQOx9l0=";
  };

  vendorSha256 = "sha256-K+/soCogskzz0C3Zjzrn3GtucefJMWsjPMvCCpghN1A=";

  doCheck = false;
}
