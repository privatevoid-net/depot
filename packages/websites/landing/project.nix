{ pkgs, ... }:

{
  projectShells.landing = {
    tools = with pkgs; [
      hugo
    ];
  };
}
