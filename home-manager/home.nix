{ config, pkgs, lib, ... }:


{
  home.username = "trace";
  home.homeDirectory = "/home/trace";

  gtk.enable = true;

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
  };

  imports = [
    ./user-apps.nix
    ./git.nix
    ./hyprland.nix
    ./waybar.nix
    ./hyprpaper.nix
    ./alacritty.nix
  ];

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  # Generate walker's default config on first deploy if it doesn't exist
  home.activation.walkerConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f "$HOME/.config/walker/config.toml" ]; then
      ${pkgs.walker}/bin/walker -C
    fi
  '';

  home.stateVersion = "25.11";
}