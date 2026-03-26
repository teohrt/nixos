# Packages that should be installed for all users - root in mind
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    git
    neovim
    eza # A modern replacement for ‘ls’
    kitty
    gnumake
    stow
  ];
}
