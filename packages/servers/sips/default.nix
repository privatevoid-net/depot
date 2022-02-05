{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "sips";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "DeedleFake";
    repo = pname;
    rev = "v${version}";
    sha256 = "0v5g4zz7j6150yk7k3svh3ffgr0ghzp5yl01bpq99i0lkpliidpx";
  };

  vendorSha256 = "sha256-JZ8wtfu+jLikTKjYt+1Zt05jNVahEyRU/ciK2n+AACc=";

  subPackages = [ "cmd/sips" "cmd/sipsctl" ];

  # HACK: this can't cross-compile
  postInstall = ''
    mkdir -p $out/share/bash-completion/completions $out/share/zsh/site-functions
    $out/bin/sipsctl completion bash > $out/share/bash-completion/completions/sipsctl
    $out/bin/sipsctl completion zsh > $out/share/zsh/site-functions/_sipsctl
  '';

  meta = with lib; {
    description = "A Simple IPFS Pinning Service";
    homepage = "https://github.com/DeedleFake/sips";
    license = licenses.mit;
    maintainers = with maintainers; [  ];
  };
}
