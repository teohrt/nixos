# Packages that should be installed to the user profile.
{ pkgs, pkgs-walker, ... }: {
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

    # app launcher / menus
    pkgs-walker.walker

    # wayland / hyprland ecosystem
    impala                # wifi TUI
    bluetui               # bluetooth TUI
    wiremix               # audio TUI
    mako                  # notification daemon
    grim                  # screenshot tool
    slurp                 # screen area selection
    wl-clipboard          # clipboard utilities (wl-copy / wl-paste)

    # fonts
    nerd-fonts.jetbrains-mono

  ];
}
