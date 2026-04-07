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

  # Floats, resizes, centers, and pins the active window. Run again to unpin and retile.
  popWindow = pkgs.writeShellScript "pop-window" ''
    active=$(hyprctl activewindow -j)
    pinned=$(echo "$active" | ${pkgs.jq}/bin/jq ".pinned")
    addr=$(echo "$active" | ${pkgs.jq}/bin/jq -r ".address")

    if [[ $pinned == "true" ]]; then
      hyprctl -q --batch \
        "dispatch pin address:$addr;" \
        "dispatch togglefloating address:$addr;"
    elif [[ -n $addr ]]; then
      hyprctl -q --batch \
        "dispatch togglefloating address:$addr;" \
        "dispatch resizeactive exact 1300 900 address:$addr;" \
        "dispatch centerwindow address:$addr;" \
        "dispatch pin address:$addr;" \
        "dispatch alterzorder top address:$addr;"
    fi
  '';

  # Reads all bindd-described bindings from Hyprland and shows them in a
  # searchable walker dmenu. Only bindings with descriptions appear.
  keybindingsMenu = pkgs.writeShellScript "keybindings-menu" ''
    hyprctl -j binds | \
      ${pkgs.jq}/bin/jq -r '
        .[] |
        select(.description != null and .description != "") |
        {
          mod: (
            if .modmask == 0 then ""
            elif .modmask == 1  then "SHIFT"
            elif .modmask == 4  then "CTRL"
            elif .modmask == 8  then "ALT"
            elif .modmask == 64 then "SUPER"
            elif .modmask == 65 then "SUPER SHIFT"
            elif .modmask == 68 then "SUPER CTRL"
            elif .modmask == 69 then "SUPER SHIFT CTRL"
            elif .modmask == 72 then "SUPER ALT"
            elif .modmask == 76 then "SUPER CTRL ALT"
            else (.modmask | tostring) end
          ),
          key: (.key | ascii_upcase),
          desc: .description
        } |
        if .mod == "" then "\(.key)  →  \(.desc)"
        else "\(.mod) + \(.key)  →  \(.desc)"
        end
      ' | \
      walker --dmenu -p "Keybindings" --width 700 --height 500
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
          "windows, 1, 2, easeOutQuart, slide"
          "windowsOut, 1, 2, easeOutQuart, slide"
          "fade, 1, 2, easeOutQuart"
          "workspaces, 1, 2, easeOutQuart, slide"
          "layers, 1, 2, easeOutQuart, popin 80%"
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
        "blur, walker"
        "ignorezero, walker"
        "animation slide top, walker"                  # slide down from top when opening
        "blur, swaync-control-center"
        "ignorezero, swaync-control-center"
        "animation slide top, swaync-control-center"   # notification panel slides down from top
      ];

      # floating window rules for TUI apps launched in titled windows
      windowrulev2 = [

        "fullscreen, class:^(screensaver)$"
        "noanim,     class:^(screensaver)$"
        "nodim,      class:^(screensaver)$"
        "noborder,   class:^(screensaver)$"

        "opacity ${toString osConfig.stylix.opacity.applications} ${toString osConfig.stylix.opacity.applications}, class:^(org.gnome.Nautilus)$"
        "opacity ${toString osConfig.stylix.opacity.terminal} ${toString osConfig.stylix.opacity.terminal}, class:^(code)$"
        "float,       class:^(org.kde.partitionmanager)$"
        "size 1300 900, class:^(org.kde.partitionmanager)$"
        "center,      class:^(org.kde.partitionmanager)$"
        "pin,         class:^(org.kde.partitionmanager)$"

        "float,       class:^(localsend_app)$"
        "size 1300 900, class:^(localsend_app)$"
        "center,      class:^(localsend_app)$"
        "pin,         class:^(localsend_app)$"

        "float, title:^(wifi)$"
        "size 900 600, title:^(wifi)$"
        "center, title:^(wifi)$"
        "animation slide top, title:^(wifi)$"
        "float, title:^(bluetooth)$"
        "size 600 400, title:^(bluetooth)$"
        "center, title:^(bluetooth)$"
        "animation slide top, title:^(bluetooth)$"
        "float, title:^(audio)$"
        "size 600 400, title:^(audio)$"
        "center, title:^(audio)$"
        "animation slide top, title:^(audio)$"
        "float, title:^(battery)$"
        "size 600 800, title:^(battery)$"
        "center, title:^(battery)$"
        "animation slide top, title:^(battery)$"
      ];

      # standard key bindings with descriptions (bindd = bind with description)
      # descriptions appear in the SUPER+K keybindings menu
      bindd = [
        "$mod, Return,       Terminal,              exec, $terminal"
        "$mod, Escape,       Power menu,            exec, power-menu"
        "$mod SHIFT, Return, Browser,               exec, google-chrome-stable"
        "$mod, F,            Fullscreen,            fullscreen"
        "$mod SHIFT, F,      File manager,          exec, nautilus --new-window"
        "$mod, W,            Close window,          killactive"

        "$mod, SPACE,        Launch apps,           exec, $menu"
        "$mod, B,            Toggle waybar,         exec, pkill -SIGUSR1 waybar"
        "$mod, J,            Toggle split,          togglesplit"
        "$mod, P,            Pseudo window,         pseudo"
        "$mod, O,            Pop window out,        exec, ${popWindow}"
        "$mod, K,            Show keybindings,      exec, ${keybindingsMenu}"

        # resize active window
        "$mod, minus,        Expand window left,  resizeactive, -100 0"
        "$mod, equal,        Shrink window left,  resizeactive, 100 0"
        "$mod SHIFT, minus,  Shrink window up,    resizeactive, 0 -100"
        "$mod SHIFT, equal,  Expand window down,  resizeactive, 0 100"

        # focus
        "$mod, left,  Move focus left,  movefocus, l"
        "$mod, right, Move focus right, movefocus, r"
        "$mod, up,    Move focus up,    movefocus, u"
        "$mod, down,  Move focus down,  movefocus, d"

        # switch workspace
        "$mod, 1, Workspace 1,  workspace, 1"
        "$mod, 2, Workspace 2,  workspace, 2"
        "$mod, 3, Workspace 3,  workspace, 3"
        "$mod, 4, Workspace 4,  workspace, 4"
        "$mod, 5, Workspace 5,  workspace, 5"
        "$mod, 6, Workspace 6,  workspace, 6"
        "$mod, 7, Workspace 7,  workspace, 7"
        "$mod, 8, Workspace 8,  workspace, 8"
        "$mod, 9, Workspace 9,  workspace, 9"
        "$mod, 0, Workspace 10, workspace, 10"

        # move active window to workspace
        "$mod SHIFT, 1, Move to workspace 1,  movetoworkspace, 1"
        "$mod SHIFT, 2, Move to workspace 2,  movetoworkspace, 2"
        "$mod SHIFT, 3, Move to workspace 3,  movetoworkspace, 3"
        "$mod SHIFT, 4, Move to workspace 4,  movetoworkspace, 4"
        "$mod SHIFT, 5, Move to workspace 5,  movetoworkspace, 5"
        "$mod SHIFT, 6, Move to workspace 6,  movetoworkspace, 6"
        "$mod SHIFT, 7, Move to workspace 7,  movetoworkspace, 7"
        "$mod SHIFT, 8, Move to workspace 8,  movetoworkspace, 8"
        "$mod SHIFT, 9, Move to workspace 9,  movetoworkspace, 9"
        "$mod SHIFT, 0, Move to workspace 10, movetoworkspace, 10"

        # mute toggles
        ", XF86AudioMute,    Mute audio, exec, swayosd-client --output-volume mute-toggle"
        ", XF86AudioMicMute, Mute mic,   exec, swayosd-client --input-volume mute-toggle"

        # screenshots — all modes save to ~/Pictures and copy to clipboard
        ", Print,      Screenshot region,  exec, hyprshot -m region -o ~/Pictures"
        "SHIFT, Print, Screenshot window,  exec, hyprshot -m window -o ~/Pictures"
        "$mod, Print,  Screenshot monitor, exec, hyprshot -m output -o ~/Pictures"
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
