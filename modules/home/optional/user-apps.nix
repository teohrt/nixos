# Packages that should be installed to the user profile.
{ pkgs, pkgs-unstable, pkgs-walker, ... }:
let
  # Wrap zoom-us to enable Wayland screen sharing via PipeWire
  zoom-wayland = pkgs.symlinkJoin {
    name = "zoom-wayland";
    paths = [ pkgs.zoom-us ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/zoom \
        --set XDG_CURRENT_DESKTOP Hyprland \
        --set XDG_SESSION_TYPE wayland \
        --set QT_QPA_PLATFORM xcb
    '';
  };
in
{
  home.packages = with pkgs; [
    # cli utilities
    terminaltexteffects  # tte — terminal text effects (used by screensaver)
    claude-code
    lazydocker
    ripgrep
    jq
    fzf
    which
    tree
    gawk
    cmatrix

    # apps
    kdePackages.partitionmanager
    google-chrome
    _1password-gui
    obsidian
    localsend
    imv                    # image viewer
    system-config-printer  # printer management GUI
    evince     # PDF viewer
    vlc        # video player
    slack
    zoom-wayland         # wrapped for Wayland screen sharing
    pkgs-unstable.bruno  # API client (like Postman) — from unstable for v3.x
    easyeffects          # audio effects for PipeWire

    mpvpaper                # animated wallpaper via mpv (supports MP4/GIF)

    # wayland / hyprland ecosystem
    pkgs-walker.walker          # app launcher / dmenu replacement
    pkgs-walker.elephant        # data provider service that indexes apps for walker
    impala                      # wifi TUI
    bluetui                     # bluetooth TUI
    wiremix                     # audio TUI
    grimblast                   # screenshot tool for Hyprland
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

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;  # faster nix shell integration via cached devShells
  };
}
