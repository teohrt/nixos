# Packages that should be installed for all users - root in mind
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    git
    neovim
    eza # A modern replacement for 'ls'
    alacritty
    vscode
    gnumake
    stow
    nerd-fonts.jetbrains-mono
    home-manager
    satty
  ];

  xdg.mime.defaultApplications = {
    "image/png" = "satty.desktop";
    "image/jpeg" = "satty.desktop";
    "image/gif" = "satty.desktop";
    "image/webp" = "satty.desktop";
    "image/bmp" = "satty.desktop";
    "image/tiff" = "satty.desktop";
  };
}
