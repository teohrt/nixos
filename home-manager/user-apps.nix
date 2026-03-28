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
    xfce.thunar
    xfce.thunar-volman          # auto-mount removable drives
    xfce.thunar-archive-plugin  # right-click archive support
    gvfs                        # trash, MTP devices, network shares

    # app launcher / menus
    pkgs-walker.walker    # app launcher / dmenu replacement
    pkgs-walker.elephant  # data provider service that indexes apps for walker

    # wayland / hyprland ecosystem
    impala                # wifi TUI
    bluetui               # bluetooth TUI
    wiremix               # audio TUI
    mako                  # notification daemon
    hyprshot              # screenshot tool (wraps grim/slurp)
    swayosd               # OSD popup for volume/brightness
    brightnessctl         # brightness control (requires video group)
    wl-clipboard          # clipboard utilities (wl-copy / wl-paste)
    wl-clip-persist       # keeps clipboard alive after source process exits

    # fonts
    nerd-fonts.jetbrains-mono

  ];
}
