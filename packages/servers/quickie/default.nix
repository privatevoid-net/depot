{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "quickie";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "schizo-org";
    repo = "schizo.cooking";
    rev = "bec0465266989a2f7520adffa30d956caffb7daf";
    sha256 = "sha256-uNsKuhWeLo6lEAGA0V8xLwQFvK3ya/YwVkLB+N8SNOc=";
  };

  makeFlags = [ "quickie" ];
  
  installFlags = [ "-C" "quickie" "install" "PREFIX=${placeholder "out"}" ];
}
