{ pkgs, ... }:

{
  environment.defaultPackages = [];

  environment.systemPackages = with pkgs; [
    android-tools
    bat
    btop
    dua
    duf
    fzf
    git
    lsd
    neovim
    ripgrep
    rsync
    strace
    wget
  ];

  environment.shellAliases = {
    bat = "bat --no-config --theme DarkNeon";
    cat = "bat -pp";
    df = "duf";
    du = "dua";
    ls = "lsd --date=relative";
    vim = "nvim";
  };

  environment.sessionVariables = {
    EDITOR = "nvim";
  };

  desktop.hiddenApps = [
    "btop.desktop"
    "htop.desktop"
    "nvim.desktop"
  ];
}
