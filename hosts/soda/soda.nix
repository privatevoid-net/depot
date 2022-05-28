{ pkgs, ... }:

{
  imports = [
    ./data
    ./shell-profile
  ];

  environment.systemPackages = with pkgs; [
    # provide some editors
    nano
    vim
    neovim
  ];
}
