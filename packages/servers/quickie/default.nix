{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "quickie";
  version = "1.2";

  src = fetchFromGitHub {
    owner = "schizo-org";
    repo = "schizo.cooking";
    rev = "db4211873ae6c1abe9fc1365b37ff5800b6a99d7";
    sha256 = "sha256-Ih2BgkPEBA6tciPyCx3hfSXoHYlqSUmwGmCQ1Cg08bE=";
  };

  makeFlags = [ "quickie" ];

  installFlags = [ "-C" "quickie" "install" "PREFIX=${placeholder "out"}" ];
}
