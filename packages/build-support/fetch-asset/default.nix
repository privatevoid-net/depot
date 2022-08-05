{ fetchurl }:

{ cdnURL ? "https://cdn.privatevoid.net/assets", index }:

let
  dvc = builtins.fromJSON (builtins.readFile index);

  inherit (builtins.head dvc.outs) sha256 path;

  hashPrefix = builtins.substring 0 2 sha256;
  hashSuffix = builtins.substring 2 (-1) sha256;
in

fetchurl {
  name = path;
  url = "${cdnURL}/${hashPrefix}/${hashSuffix}";
  inherit sha256;
}
