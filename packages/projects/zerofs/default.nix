{ rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage {
  pname = "zerofs";
  version = "0.18.0";

  src = fetchFromGitHub {
    owner = "Barre";
    repo = "ZeroFS";
    rev = "d20defb22f9fbd38a6fd0b0709873c155d2bc95a";
    sha256 = "sha256-G+kXAlPfo3YhAGy9nkKCL7384dWUvPr4cZ+WIX99OSc=";
  };

  postUnpack = "sourceRoot=$sourceRoot/zerofs";

  cargoHash = "sha256-XbjtlWQkXanOo7SbbgsZNXj5SKy0PQAd2eRM/9f9gLs=";
}
