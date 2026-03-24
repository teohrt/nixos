# Packages that should be installed to the user profile.
{ pkgs, ... }: {
  home.packages = with pkgs; [
    # cli utilities
    ripgrep
    jq
    fzf
    which
    tree
    gawk
    btop
    neofetch

    # apps
    vscode
    google-chrome

    # wayland / hyprland ecosystem
    kitty         # terminal (Hyprland $terminal; needs profile for wofi drun)
    waybar        # status bar
    wofi          # app launcher
    mako          # notification daemon
    hyprpaper     # wallpaper
    grim          # screenshot tool
    slurp         # screen area selection
    wl-clipboard  # clipboard utilities (wl-copy / wl-paste)
  ];
}
