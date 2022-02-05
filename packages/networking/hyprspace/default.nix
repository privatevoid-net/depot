{ lib, stdenv, buildGoModule, fetchFromGitHub, iproute2mac }:

buildGoModule rec {
  pname = "hyprspace";
  version = "0.2.2";

  propagatedBuildInputs = lib.optional stdenv.isDarwin iproute2mac;

  patches = [
    ./0001-Lain-ipfs-bootstrap-nodes.patch
    ./0002-Remove-quic-transport-for-Lain-ipfs.patch
    ./0003-Remove-dep-from-go.mod.patch
  ];

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-UlIQCy4moW58tQ1dqxrPsU5LN1Bs/Jy5X+2CEmXdYIk=";
  };

  vendorSha256 = "sha256-8j9M8LrcqiPShCCNOmmJoY6wclHRiX2xOJH/wvlwvwY=";

  meta = with lib; {
    description = "A Lightweight VPN Built on top of Libp2p for Truly Distributed Networks.";
    homepage = "https://github.com/hyprspace/hyprspace";
    license = licenses.asl20;
    maintainers = with maintainers; [ yusdacra ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
