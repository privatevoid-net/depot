{
  writeShellApplication,
  nix, npins
}:

writeShellApplication {
  name = "pin";
  runtimeInputs = [
    nix
    npins
  ];
  text = builtins.readFile ./pin.sh;
}
