{
  writeShellApplication,
  nix, npins, jq
}:

writeShellApplication {
  name = "pin";
  runtimeInputs = [
    nix
    npins
    jq
  ];
  text = builtins.readFile ./pin.sh;
}
