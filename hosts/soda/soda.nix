{
  imports = [
    ./data
    ./shell-profile
  ];

  environment.systemPackages = [
    # provide some editors
    nano
    vim
    neovim
  ];
}
