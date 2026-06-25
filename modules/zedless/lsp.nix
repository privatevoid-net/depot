{ lib, pkgs, ... }:

{
  programs.zedless.settings = {
    lsp = {
      nil.binary.path = lib.getExe pkgs.nil;
      marksman.binary.path = lib.getExe pkgs.marksman;
      gopls.binary.path = lib.getExe pkgs.gopls;
      json-language-server.binary = {
        path = "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server";
        arguments = [ "--stdio" ];
      };
      pyright.binary = {
        path = "${pkgs.pyright}/bin/pyright-langserver";
        arguments = [ "--stdio" ];
      };
      tombi.binary = {
        path = lib.getExe pkgs.tombi;
        arguments = [ "lsp" ];
      };
    };
    languages = {
      JSON.language_servers = [ "json-language-server" ];
      Nix.language_servers = [ "nil" ];
      Python.language_servers = [ "pyright" ];
    };
  };
}
