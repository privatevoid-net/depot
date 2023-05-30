{
  writeShellApplication,
  curl, gum, jq
}:

writeShellApplication {
  name = "graf";
  runtimeInputs = [
    curl
    gum
    jq
  ];
  text = builtins.readFile ./graf.sh;
}
