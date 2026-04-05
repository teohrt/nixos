{ pkgs, osConfig, ... }:
let
  # Listens on Hyprland's IPC event socket and kills walker whenever the active
  # workspace changes. Needed because walker is a layer surface (not a window)
  # so it persists across workspace switches and ignores normal focus-loss rules.
  closeWalkerOnWorkspaceSwitch = pkgs.writeShellScript "close-walker-on-workspace-switch" ''
    socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
    ${pkgs.socat}/bin/socat -u "UNIX-CONNECT:$socket" - | while IFS= read -r line; do
      case "$line" in
        workspace\>\>*) pkill walker || true ;;
      esac
    done
  '';
in

{
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      # use preferred resolution, auto-position, 1.2x scaling
      monitor = ",preferred,auto,1.2";

      "$terminal" = "alacritty";
      "$menu" = "walker -N -H";
      "$mod" = "SUPER";

      exec-once = [
        "swayosd-server"                                   # OSD server for volume/brightness popups
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" # auth agent for privilege escalation prompts
        "${pkgs.mako}/bin/mako"                            # notification daemon
        "elephant"                                         # indexes apps for walker to search
        "sleep 2 && walker --gapplication-service"         # walker background service (delayed to let elephant index first)
        "${closeWalkerOnWorkspaceSwitch}"                  # close walker on workspace switch (layer surfaces ignore normal focus rules)
        "wl-clip-persist --clipboard regular"              # keep clipboard alive after source process exits
      ];

      env = [
        # cursor size/theme for both X and Hypr cursor protocols
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,Adwaita"
        "HYPRCURSOR_SIZE,24"
        "HYPRCURSOR_THEME,Adwaita"
        # tell nixpkgs Electron apps (Spotify, Slack, VS Code, etc.) to use native
        # Wayland rendering — avoids XWayland upscaling blur at fractional scales
        "NIXOS_OZONE_WL,1"
        # force Qt apps (Zoom, etc.) to use native Wayland — falls back to X11 if needed
        "QT_QPA_PLATFORM,wayland;xcb"
      ];

      general = {
        gaps_in = 5;   # gap between tiled windows
        gaps_out = 10; # gap between windows and screen edge
        border_size = 1;
        layout = "dwindle"; # binary space partitioning layout
      };

      animations = {
        enabled = true;
        # smooth deceleration curve for all animations
        bezier = "easeOutQuart, 0.25, 1, 0.5, 1";
        animation = [
          "windows, 1, 4, easeOutQuart, slide"
          "windowsOut, 1, 4, easeOutQuart, slide"
          "fade, 1, 4, easeOutQuart"
          "workspaces, 1, 2, easeOutQuart, slide"
          "layers, 1, 4, easeOutQuart, popin 80%"
        ];
      };

      decoration = {
        rounding = 10; # rounded corners radius (px)
        blur = {
          enabled = true;
          size = 4;
          passes = 3;
          vibrancy = 0.2;
          contrast = 1.1;
          noise = 0.02;
        };
      };

      input = {
        kb_layout = "us";
        follow_mouse = 1; # focus follows mouse
        sensitivity = 0;  # 0 = no pointer speed adjustment
      };

      dwindle = {
        pseudotile = true;     # allow manual resizing of tiled windows
        preserve_split = true; # keep split direction when moving windows
      };

      xwayland = {
        # render XWayland apps at native pixel resolution instead of upscaling from 1x
        # fixes blurriness in apps like Zoom that can't use native Wayland
        force_zero_scaling = true;
      };

      layerrule = [
        "blur, waybar"
        "ignorezero, waybar"
        "blur, walker"          # walker is a layer surface — blur must be set via layerrule, not windowrulev2
        "ignorezero, walker"   # don't blur fully-transparent pixels (outside the rounded box)
      ];

      # floating window rules for TUI apps launched in titled windows
      windowrulev2 = [
        "opacity ${toString osConfig.stylix.opacity.applications} ${toString osConfig.stylix.opacity.applications}, class:^(org.gnome.Nautilus)$"
"float, title:^(wifi)$"
        "size 900 600, title:^(wifi)$"
        "center, title:^(wifi)$"
        "float, title:^(bluetooth)$"
        "size 600 400, title:^(bluetooth)$"
        "center, title:^(bluetooth)$"
        "float, title:^(audio)$"
        "size 600 400, title:^(audio)$"
        "center, title:^(audio)$"
      ];

      # standard key bindings (fire once per press)
      bind = [
        "$mod, Return,       exec, $terminal"
        "$mod, Escape,       exec, power-menu"
        "$mod SHIFT, Return, exec, google-chrome-stable"
        "$mod, F,            fullscreen"
        "$mod SHIFT, F,      exec, nautilus --new-window"  # file browser
        "$mod, W,            killactive"
        "$mod, ESC,          exit"
        "$mod SHIFT, V,      togglefloating"
        "$mod, SPACE,        exec, $menu"
        "$mod, J,            togglesplit"

        # focus
        "$mod, left,  movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up,    movefocus, u"
        "$mod, down,  movefocus, d"

        # switch workspace
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # move active window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        # mute toggles (swayosd shows the OSD popup)
        ", XF86AudioMute,    exec, swayosd-client --output-volume mute-toggle"
        ", XF86AudioMicMute, exec, swayosd-client --input-volume mute-toggle"

        # screenshot — all modes save to ~/Pictures and copy to clipboard
        ", Print,       exec, hyprshot -m region -o ~/Pictures"  # select region
        "SHIFT, Print,  exec, hyprshot -m window -o ~/Pictures"  # click a window
        "$mod, Print,   exec, hyprshot -m output -o ~/Pictures"  # full monitor
      ];

      # repeatable bindings — fire continuously while key is held
      bindel = [
        ", XF86AudioRaiseVolume,  exec, swayosd-client --output-volume raise"
        ", XF86AudioLowerVolume,  exec, swayosd-client --output-volume lower"
        ", XF86MonBrightnessUp,   exec, swayosd-client --brightness raise"
        ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
      ];

      # mouse bindings (held modifier + mouse button)
      bindm = [
        "$mod, mouse:272, movewindow"   # left click drag — move window
        "$mod, mouse:273, resizewindow" # right click drag — resize window
      ];
    };
  };
}
