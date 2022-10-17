{ pkgs, ... }:
let
  component = name: builtins.readFile (builtins.toString ../../config/zsh/components + "/${name}.zsh");

  snippets = map component [
    "console-256color"
    "fuzzy-tab"
    "magic-space"
    "navigation"
  ] ++ [
    "source ${pkgs.fzf}/share/fzf/key-bindings.zsh"
  ];
in {
  environment.shellAliases = {
    cat = "${pkgs.bat} -p";
    doas = "doas ";
    ip = "ip -c";
    ls = "${pkgs.lsd}";
    sudo = "sudo ";
    tree = "${pkgs.lsd} --tree";
    uctl = "systemctl --user";
    nix-repl = "nix repl '<repl>'";
  };
  programs = {
    zsh = {
      enable = true;
      histFile = "$HOME/.cache/zsh_history";
      histSize = 15000;
      setOptions = [
        "autocd"
        "autopushd"
        "globcomplete"
        "globstarshort"
        "histexpiredupsfirst"
        "histfcntllock"
        "histignoredups"
        "histnofunctions"
        "histnostore"
        "histreduceblanks"
        "histverify"
        "interactivecomments"
        "monitor"
        "nobadpattern"
        "promptsubst"
        "sharehistory"
        "zle"
      ];

      vteIntegration = true;

      promptInit = builtins.readFile ../../config/zsh/prompt.zsh;
      interactiveShellInit = builtins.concatStringsSep "\n" snippets;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting = {
        enable = true;
        highlighters = [ "main" "pattern" ];
        styles = {
          "precommand" = "fg=33";
          "arg0" = "fg=39";
          "single-hyphen-option" = "fg=229";
          "double-hyphen-option" = "fg=228";
          "path" = "none";
        };

        # these are aliases, highlight them properly regardless
        patterns = {
          "doas" = "fg=33";
          "sudo" = "fg=33";
        };
      };
    };
  };
}
