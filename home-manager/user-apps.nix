# Packages that should be installed to the user profile.
{ pkgs, pkgs-walker, ... }: {
  home.packages = with pkgs; [
    # cli utilities
    claude-code
    lazydocker
    ripgrep
    jq
    fzf
    which
    tree
    gawk

    # apps
    google-chrome
    _1password-gui
    obsidian
    localsend
    imv                    # image viewer
    system-config-printer  # printer management GUI
    evince     # PDF viewer
    vlc        # video player
    slack
    zoom-us

    mpvpaper                # animated wallpaper via mpv (supports MP4/GIF)

    # wayland / hyprland ecosystem
    pkgs-walker.walker          # app launcher / dmenu replacement
    pkgs-walker.elephant        # data provider service that indexes apps for walker
    impala                      # wifi TUI
    bluetui                     # bluetooth TUI
    wiremix                     # audio TUI
    hyprshot                    # screenshot tool (wraps grim/slurp)
    swayosd                     # OSD popup for volume/brightness
    brightnessctl               # brightness control (requires video group)
    wl-clipboard                # clipboard utilities (wl-copy / wl-paste)
    wl-clip-persist             # keeps clipboard alive after source process exits
    nautilus                    # file manager
    nautilus-python             # enables right-click extensions (e.g. open in terminal)
    file-roller                 # right-click archive extract/compress
    ffmpegthumbnailer           # video thumbnails in nautilus
    gvfs                        # trash, MTP devices, network shares

    # fonts
    nerd-fonts.jetbrains-mono
  ];
}
