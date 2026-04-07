# Packages that should be installed to the user profile.
{ pkgs, pkgs-walker, ... }:
let
  # GParted is an X11 app that elevates to root via polkit. On Wayland, root doesn't
  # have display access by default — xhost grants it before launch and revokes on exit.
  # trap ensures revoke runs even if GParted crashes.
  gparted = pkgs.writeShellScriptBin "gparted" ''
    ${pkgs.xorg.xhost}/bin/xhost +SI:localuser:root
    trap '${pkgs.xorg.xhost}/bin/xhost -SI:localuser:root' EXIT
    ${pkgs.gparted}/bin/gparted "$@"
  '';
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
    gparted
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

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;  # faster nix shell integration via cached devShells
  };
}
