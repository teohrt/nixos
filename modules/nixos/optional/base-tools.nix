{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    neovim
    eza
    gnumake
    stow
    zoxide
    home-manager
  ];
}
