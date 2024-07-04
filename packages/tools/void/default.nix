{ lib, buildGoModule, fetchFromGitHub, installShellFiles }:

let
  version = "0.15.0+dev";
  rev = "6461b31e4458dbce655fa1db6d266f666dbdfc4e";
in
buildGoModule rec {

  inherit version;
  pname = "void";

  meta = {
    description = "Paisano CLI/TUI, customized for Private Void";
    license = lib.licenses.unlicense;
    homepage = "https://github.com/paisano-nix/tui";
  };

  src = fetchFromGitHub {
    owner = "paisano-nix";
    repo = "tui";
    inherit rev;
    hash = "sha256-EFDb8jfv2SH57a6CfDo0WU4XjDihhgvVnKKw20yqksc=";
  };

  postPatch = ''
    substituteInPlace flake/flake.go --replace-fail __std lib.catalog
    substituteInPlace env/env.go --replace-fail '"metadata"' '"void-cli-metadata"'
  '';

  sourceRoot = "source/src";

  vendorHash = "sha256-S1oPselqHRIPcqDSsvdIkCwu1siQGRDHOkxWtYwa+g4=";

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    mv $out/bin/paisano $out/bin/void

    installShellCompletion --cmd void \
      --bash <($out/bin/void _carapace bash) \
      --fish <($out/bin/void _carapace fish) \
      --zsh <($out/bin/void _carapace zsh)
  '';

  ldflags = [
    "-s"
    "-w"
    "-X main.buildVersion=${version}"
    "-X main.buildCommit=${rev}"
    "-X main.argv0=void"
    "-X main.project=Depot"
  ];
}
