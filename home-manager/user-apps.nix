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

    # apps
    google-chrome

    # wayland / hyprland ecosystem
    networkmanagerapplet  # nm-connection-editor GUI
    pavucontrol           # PulseAudio volume control GUI
    mako                  # notification daemon
    hyprpaper             # wallpaper
    grim                  # screenshot tool
    slurp                 # screen area selection
    wl-clipboard          # clipboard utilities (wl-copy / wl-paste)

    # fonts
    nerd-fonts.jetbrains-mono

  ];
}
