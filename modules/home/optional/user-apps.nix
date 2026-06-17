# Packages that should be installed to the user profile.
{ pkgs, pkgs-unstable, ... }:
let
  # Wrap DBeaver to bypass Stylix's GTK theme (Java/SWT apps render incorrectly with it)
  dbeaver-unwrapped = pkgs.symlinkJoin {
    name = "dbeaver-unstyled";
    paths = [ pkgs-unstable.dbeaver-bin ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/dbeaver \
        --set GTK2_RC_FILES /dev/null \
        --set SWT_GTK3 0 \
        --unset GTK_THEME \
        --unset GTK_ICON_THEME
    '';
  };

  # Bruno v3 from binary release (nixpkgs only has v2)
  bruno-v3 = pkgs.stdenv.mkDerivation rec {
    pname = "bruno";
    version = "3.3.0";

    src = pkgs.fetchurl {
      url = "https://github.com/usebruno/bruno/releases/download/v${version}/bruno_${version}_amd64_linux.deb";
      sha256 = "sha256-0xjCsa2tAM0uQOQlU5H2SwVkzDK0a5jJCchF6X1nYrg=";
    };

    nativeBuildInputs = with pkgs; [ dpkg autoPatchelfHook makeWrapper wrapGAppsHook3 ];

    buildInputs = with pkgs; [
      alsa-lib
      at-spi2-atk
      cairo
      cups
      dbus
      expat
      gdk-pixbuf
      glib
      gtk3
      nss
      nspr
      xorg.libX11
      xorg.libxcb
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      pango
      systemd
      libdrm
      mesa
      libxkbcommon
      libGL
      vulkan-loader
      stdenv.cc.cc.lib  # libstdc++.so.6, required by Bruno's native modules
    ];

    unpackCmd = "dpkg-deb -x $curSrc .";
    sourceRoot = ".";

    dontConfigure = true;
    dontBuild = true;
    dontWrapGApps = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r opt/Bruno/* $out/
      cp -r usr/share $out/
      mkdir -p $out/bin

      # Desktop entry
      cat > $out/share/applications/bruno.desktop <<EOF
      [Desktop Entry]
      Name=Bruno
      Exec=bruno %U
      Icon=bruno
      Type=Application
      Categories=Development;
      StartupWMClass=Bruno
      EOF

      runHook postInstall
    '';

    preFixup = ''
      makeWrapper "$out/bruno" "$out/bin/bruno" \
        "''${gappsWrapperArgs[@]}" \
        --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath buildInputs}"
    '';

    meta = with pkgs.lib; {
      description = "Opensource API Client (lightweight alternative to Postman/Insomnia)";
      homepage = "https://www.usebruno.com";
      license = licenses.mit;
      platforms = [ "x86_64-linux" ];
    };
  };

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
    nodejs
    lazydocker
    ripgrep
    jq
    fzf
    which
    tree
    gawk
    cmatrix
    go
    pkgs-unstable.smassh

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
    bubblewrap              # sandbox for Claude Desktop Cowork mode
    zoom-wayland         # wrapped for Wayland screen sharing
    bruno-v3             # API client (like Postman) — v3 from binary release
    easyeffects          # audio effects for PipeWire
    dbeaver-unwrapped          # database client (PostgreSQL, MySQL, SQLite, etc.)

    # wayland / hyprland ecosystem
    impala                      # wifi TUI
    bluetui                     # bluetooth TUI
    wiremix                     # audio TUI
    grimblast                   # screenshot tool for Hyprland
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
