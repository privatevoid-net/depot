{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "quickie";
  version = "1.1";

  src = fetchFromGitHub {
    owner = "schizo-org";
    repo = "schizo.cooking";
    rev = "690349a92f60dd3dd10af3bf26c1f99ee83349b8";
    sha256 = "sha256-1RzDsISk6E+XUxVY9fHPSjOExzkLykhtpaBeFHpFEb4=";
  };
  
  postPatch = ''
    substituteInPlace quickie/quickie.c --replace-fail IN_NONBLOCK 0
  '';

  makeFlags = [ "quickie" ];
  
  installFlags = [ "-C" "quickie" "install" "PREFIX=${placeholder "out"}" ];
}
