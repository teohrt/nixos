# Packages that should be installed for all users - root in mind
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    neovim
    eza # A modern replacement for 'ls'
    kitty
    vscode
    gnumake
    stow
    zoxide
    nerd-fonts.jetbrains-mono
    home-manager
    satty
    sops
  ];

  xdg.mime.defaultApplications = {
    "inode/directory" = "org.gnome.Nautilus.desktop";
    "image/png" = "satty.desktop";
    "image/jpeg" = "satty.desktop";
    "image/gif" = "satty.desktop";
    "image/webp" = "satty.desktop";
    "image/bmp" = "satty.desktop";
    "image/tiff" = "satty.desktop";
  };
}
