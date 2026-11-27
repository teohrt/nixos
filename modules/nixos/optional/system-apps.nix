{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    kitty
    vscode
    nerd-fonts.jetbrains-mono
    satty
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
