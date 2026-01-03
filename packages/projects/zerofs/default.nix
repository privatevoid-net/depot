{ rustPlatform, fetchFromGitHub, cmake, pkg-config, openssl }:

rustPlatform.buildRustPackage rec {
  pname = "zerofs";
  version = "0.22.10";

  src = fetchFromGitHub {
    owner = "Barre";
    repo = "ZeroFS";
    rev = "v${version}";
    sha256 = "sha256-hg0vHnaqG375S5x9xTm5+d6+0Qyn7AqmNzOjfONObBk=";
  };

  nativeBuildInputs = [
    cmake
    # pkg-config
  ];

  buildInputs = [
    # openssl
  ];

  env.RUSTFLAGS = "--cfg tokio_unstable";

  postUnpack = "sourceRoot=$sourceRoot/zerofs";

  cargoHash = "sha256-En898CWUGVC6Jc7h4ZvGObs6TZihSw57nUrmlJY9mpE=";
}
