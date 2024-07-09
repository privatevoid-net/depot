{ stdenv, lib, fetchFromGitHub, buildGoModule, installShellFiles, nixosTests
, makeWrapper
, gawk
, glibc
}:

buildGoModule rec {
  pname = "openbao";
  version = "2.0.0-beta20240618";

  src = fetchFromGitHub {
    owner = "openbao";
    repo = "openbao";
    rev = "v${version}";
    sha256 = "sha256-fvopKHLFMxDZUGg6BEWEEZwea6QO57Aa5JziKVulUqE=";
  };

  vendorHash = "sha256-Bm0PxFqEXL8G4D5oygb3aDzK7clv/KtKexFMpCnHlg8=";

  proxyVendor = true;

  subPackages = [ "." ];

  nativeBuildInputs = [ installShellFiles makeWrapper ];

  tags = [ "vault" ];

  ldflags = [
    "-s" "-w"
    "-X github.com/openbao/openbao/version.GitCommit=${src.rev}"
    "-X github.com/openbao/openbao/version.Version=${version}"
    "-X github.com/openbao/openbao/version.VersionPrerelease="
  ];

  postInstall = ''
    echo "complete -C $out/bin/openbao vault" > vault.bash
    installShellCompletion vault.bash
  '' + lib.optionalString stdenv.isLinux ''
    wrapProgram $out/bin/openbao \
      --prefix PATH ${lib.makeBinPath [ gawk glibc ]}
    ln -s openbao $out/bin/bao
    ln -s openbao $out/bin/vault
  '';

  passthru.tests = { inherit (nixosTests) vault vault-postgresql vault-dev vault-agent; };

  meta = with lib; {
    homepage = "https://openbao.org/";
    description = "A tool for managing secrets";
    license = licenses.mpl20;
    mainProgram = "vault";
  };
}
