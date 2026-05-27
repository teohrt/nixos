# Hyprland window manager configuration: keybindings, window rules, animations,
# and helper scripts for screenshots, screen recording, voice input, etc.
{ pkgs, lib, config, ... }:
let
  defaultScale = "1.25";

  # Generates window rules for a centered floating popup with consistent styling.
  # Used by LocalSend, 1Password, etc.
  # `match` is the windowrulev2 selector (e.g. "class:^(1Password)$").
  # All popups are sized to half the monitor dimensions.
  floatingPopupRules = match: [
    "float, ${match}"
    "size 50% 50%, ${match}"
    "center, ${match}"
    "bordersize 1, ${match}"
    "bordercolor rgba(${config.lib.stylix.colors.base0D}ff), ${match}"
  ];

  # When a new window opens on a workspace that has a solo floating kitty,
  # unfloat the kitty so both windows tile. This complements the terminalHere
  # script which floats kitty on empty workspaces for a centered single-window look.
  unfloatOnNewWindow = pkgs.writeShellScript "unfloat-on-new-window" ''
    socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
    ${pkgs.socat}/bin/socat -u "UNIX-CONNECT:$socket" - | while IFS= read -r line; do
      case "$line" in
        openwindow\>\>*)
          # Extract fields from: openwindow>>ADDR,WORKSPACE,CLASS,TITLE
          IFS=',' read -r addr_field ws class title <<< "''${line#openwindow>>}"

          # Skip floating terminals with specific titles
          case "$title" in
            hyprmon|webcam) continue ;;
          esac

          # Find floating kitty windows on that workspace and unfloat them
          floating=$(hyprctl clients -j | ${pkgs.jq}/bin/jq -r \
            ".[] | select(.workspace.id == $ws and .floating == true and .class == \"kitty\") | .address")
          for addr in $floating; do
            hyprctl dispatch togglefloating "address:$addr"
          done
          ;;
      esac
    done
  '';

  # Auto-mirror: when external monitor connects, make laptop (eDP-*) mirror it
  # Both displays use defaultScale; on disconnect, internal is restored
  autoMirror = pkgs.writeShellScript "auto-mirror" ''
    # Kill any other instances (not ourselves)
    for pid in $(pgrep -f "auto-mirror"); do
      if [[ "$pid" != "$$" ]]; then
        kill "$pid" 2>/dev/null || true
      fi
    done

    get_internal() {
      hyprctl monitors all -j | ${pkgs.jq}/bin/jq -r '.[] | select(.name | startswith("eDP")) | .name' | head -1
    }

    get_external() {
      hyprctl monitors all -j | ${pkgs.jq}/bin/jq -r '.[] | select(.name | startswith("eDP") | not) | .name' | head -1
    }

    handle_connect() {
      local internal=$(get_internal)
      local external=$(get_external)
      [[ -z "$internal" || -z "$external" ]] && return

      # catch-all monitor rule doesn't apply to hotplugged displays; set scale explicitly
      hyprctl keyword monitor "$external,preferred,auto,${defaultScale}"
      hyprctl keyword monitor "$internal,preferred,auto,${defaultScale},mirror,$external"
    }

    handle_disconnect() {
      local internal=$(get_internal)
      [[ -z "$internal" ]] && return

      # Restore internal monitor config
      hyprctl keyword monitor "$internal,preferred,auto,${defaultScale}"
    }

    # Handle current state on startup
    sleep 1
    [[ -n "$(get_external)" ]] && handle_connect

    # Listen for monitor events
    ${pkgs.socat}/bin/socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
      case "$line" in
        monitoraddedv2*)
          sleep 0.5
          handle_connect
          ;;
        monitorremoved*)
          # Extract monitor name from event: "monitorremoved>>NAME"
          removed_monitor="''${line#*>>}"
          # Only handle removal of external monitors, ignore internal (eDP)
          [[ "$removed_monitor" == eDP* ]] && continue
          sleep 0.5
          handle_disconnect
          ;;
        configreloaded*)
          # NixOS rebuilds regenerate hyprland.conf, triggering a config reload.
          # Reloads clear runtime `hyprctl keyword` overrides, resetting monitor
          # scaling. Re-apply the external monitor setup to restore defaultScale.
          sleep 0.5
          [[ -n "$(get_external)" ]] && handle_connect
          ;;
      esac
    done
  '';

  # Floats, resizes, centers, and pins the active window. Run again to unpin and retile.
  # Size is half the monitor dimensions (same as centered terminal behavior).
  popWindow = pkgs.writeShellScript "pop-window" ''
    active=$(hyprctl activewindow -j)
    pinned=$(echo "$active" | ${pkgs.jq}/bin/jq ".pinned")
    addr=$(echo "$active" | ${pkgs.jq}/bin/jq -r ".address")

    if [[ $pinned == "true" ]]; then
      hyprctl -q --batch \
        "dispatch pin address:$addr;" \
        "dispatch togglefloating address:$addr;"
    elif [[ -n $addr ]]; then
      hyprctl dispatch togglefloating address:$addr
      hyprctl dispatch resizeactive exact 50% 50%
      hyprctl dispatch centerwindow address:$addr
      hyprctl -q --batch \
        "dispatch pin address:$addr;" \
        "dispatch alterzorder top address:$addr;"
    fi
  '';

  # Takes a screenshot, copies to clipboard, and shows notification. Click notification to edit in Satty.
  # Select region first, then hide cursor, capture, and restore cursor.
  screenshot = pkgs.writeShellScript "screenshot" ''
    file=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
    mkdir -p ~/Pictures/Screenshots

    # Select region first (cursor visible)
    region=$(${pkgs.slurp}/bin/slurp) || exit 1

    # Hide cursor by moving it off-screen, capture, then restore
    cursorpos=$(hyprctl cursorpos)
    hyprctl dispatch movecursor 99999 99999
    ${pkgs.grim}/bin/grim -g "$region" "$file"
    result=$?
    hyprctl dispatch movecursor ''${cursorpos// / }

    [[ $result -ne 0 ]] && exit 1

    # Copy to clipboard
    ${pkgs.wl-clipboard}/bin/wl-copy < "$file"

    # Notification in background so script doesn't block
    (
      action=$(${pkgs.libnotify}/bin/notify-send -a "Screenshot" -i "$file" \
        "Screenshot saved" "$file" \
        --action="default=Open" \
        --action="edit=Edit")
      case "$action" in
        default) xdg-open "$file" ;;
        edit) ${pkgs.satty}/bin/satty --filename "$file" ;;
      esac
    ) &
  '';

  # Opens kitty in the focused terminal's working directory (or home if not a terminal)
  # If workspace is empty, centers the terminal; otherwise tiles normally.
  # A separate IPC listener (unfloatOnNewWindow) handles unfloating when any
  # new window joins the workspace.
  terminalHere = pkgs.writeShellScript "terminal-here" ''
    pid=$(hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.pid')
    dir="$HOME"
    if [[ -n "$pid" && "$pid" != "null" ]]; then
      # Find shell process among descendants (zsh, bash, fish, nu)
      shell_pid=""
      for child in $(${pkgs.procps}/bin/pgrep -P "$pid"); do
        # Check direct children
        if ${pkgs.procps}/bin/ps -p "$child" -o comm= | ${pkgs.gnugrep}/bin/grep -qE '^(zsh|bash|fish|nu)$'; then
          shell_pid=$child
          break
        fi
        # Check grandchildren
        for grandchild in $(${pkgs.procps}/bin/pgrep -P "$child"); do
          if ${pkgs.procps}/bin/ps -p "$grandchild" -o comm= | ${pkgs.gnugrep}/bin/grep -qE '^(zsh|bash|fish|nu)$'; then
            shell_pid=$grandchild
            break 2
          fi
        done
      done
      if [[ -n "$shell_pid" ]] && [[ -d "/proc/$shell_pid/cwd" ]]; then
        dir=$(readlink "/proc/$shell_pid/cwd")
      fi
    fi

    # Check if current workspace is empty
    workspace=$(hyprctl activeworkspace -j | ${pkgs.jq}/bin/jq -r '.id')
    window_count=$(hyprctl clients -j | ${pkgs.jq}/bin/jq "[.[] | select(.workspace.id == $workspace)] | length")

    if [[ "$window_count" -eq 0 ]]; then
      # Empty workspace: launch, float, resize to half screen, and center
      kitty --directory "$dir" &
      sleep 0.1
      hyprctl --batch "dispatch togglefloating; dispatch resizeactive exact 50% 50%; dispatch centerwindow"
    else
      exec kitty --directory "$dir"
    fi
  '';

  # Voice-to-text using whisper-cpp
  # First press starts recording, second press stops and transcribes
  voiceInput = pkgs.writeShellScript "voice-input" ''
    MODEL_DIR="$HOME/.local/share/whisper"
    MODEL="$MODEL_DIR/ggml-base.en.bin"
    RECORDING="/tmp/voice-input.wav"

    # Download model if not present
    if [[ ! -f "$MODEL" ]]; then
      mkdir -p "$MODEL_DIR"
      ${pkgs.libnotify}/bin/notify-send -u low "Downloading speech model..." "This only happens once"
      ${pkgs.curl}/bin/curl -L -o "$MODEL" \
        "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"
    fi

    if pgrep -f "pw-record.*voice-input" > /dev/null; then
      # Stop recording and transcribe
      pkill -f "pw-record.*voice-input"
      sleep 0.2
      ${pkgs.libnotify}/bin/notify-send -u low "Transcribing..."
      text=$(${pkgs.whisper-cpp}/bin/whisper-cli -m "$MODEL" -f "$RECORDING" -np 2>/dev/null \
        | sed 's/^\[[^]]*\] *//' \
        | grep -v '^[[:space:]]*$' \
        | tr '\n' ' ' \
        | sed 's/  */ /g; s/^ *//; s/ *$//')
      rm -f "$RECORDING"
      if [[ -n "$text" ]]; then
        ${pkgs.wtype}/bin/wtype "$text"
      fi
    else
      # Start recording
      ${pkgs.libnotify}/bin/notify-send -u low "Recording... Press Super+/ to stop"
      ${pkgs.pipewire}/bin/pw-record --target=@DEFAULT_SOURCE@ "$RECORDING" &
    fi
  '';
in

{
  home.packages = [ pkgs.hyprmon pkgs.wf-recorder pkgs.whisper-cpp pkgs.wtype ];

  systemd.user.tmpfiles.rules = [
    "d %h/Pictures/Screenshots 0755 - - -"
  ];

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      monitor = ",preferred,auto,${defaultScale}";

      "$terminal" = "kitty";
      "$noctalia" = "noctalia-shell ipc call";
      "$mod" = "SUPER";

      exec-once = [
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" # auth agent for privilege escalation prompts
        "${unfloatOnNewWindow}"                              # unfloat solo floating kitty when another window joins the workspace
        "wl-clip-persist --clipboard regular"              # keep clipboard alive after source process exits
        "${autoMirror}"                                    # auto-mirror laptop to external monitor when connected
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
        gaps_in = 0;
        gaps_out = 0;
        border_size = 1;
        no_border_on_floating = false;
        "col.active_border" = lib.mkForce "rgba(${config.lib.stylix.colors.base0D}ff)";
        "col.inactive_border" = lib.mkForce "rgba(${config.lib.stylix.colors.base0D}ff)";
        layout = "dwindle"; # binary space partitioning layout
      };


      misc = {
        focus_on_activate = true; # switch to workspace when app requests focus
      };

      animations = {
        enabled = false;
        # smooth deceleration curve for all animations
        bezier = "easeOutQuart, 0.25, 1, 0.5, 1";
        animation = [
          "windows, 1, 0.25, easeOutQuart, popin 80%"
          "windowsOut, 1, 0.25, easeOutQuart, popin 80%"
          "fade, 1, 2, easeOutQuart"
          "workspaces, 1, 0.25, easeOutQuart, fade"
          "layers, 1, 0.25, easeOutQuart, popin 80%"
        ];
      };

      decoration = {
        rounding = 0;
        blur = {
          enabled = true;
          size = 6;
          passes = 4;
          vibrancy = 0.2;
          contrast = 1.1;
          noise = 0.02;
        };
      };

      input = {
        kb_layout = "us";
        follow_mouse = 1;   # focus follows mouse
        sensitivity = 0;    # 0 = no pointer speed adjustment
        repeat_rate = 50;   # keys per second when held (default: 25)
        repeat_delay = 300; # ms before repeat starts (default: 600)

        touchpad = {
          disable_while_typing = false;
        };
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
        "noanim, selection"                            # no animation for slurp (screenshot selection)
      ];

      # remove borders when only one tiled window on a workspace
      workspace = [
        "w[tv1], gapsout:0, gapsin:0"
        "f[1], gapsout:0, gapsin:0"
      ];

      windowrulev2 = [
        "bordersize 0, floating:0, onworkspace:w[tv1]"
        "bordersize 0, floating:0, onworkspace:f[1]"

        "workspace 1, class:^(chromium-browser|google-chrome|Chromium)$"
        "workspace 2, class:^(kitty)$, initialTitle:^(kitty)$"
        "workspace 3, class:^(code|Code|code-url-handler)$"
        "workspace 4, class:^(bruno)$"
        "workspace 4, class:^(DBeaver)$"
        "workspace 6, class:^(Slack|slack)$"
        "workspace 7, class:^(obsidian)$"
        "workspace 8, class:^(spotify|Spotify)$"
        "workspace 10, class:^(zoom)$"

        "fullscreen, class:^(screensaver)$"
        "noanim,     class:^(screensaver)$"
        "nodim,      class:^(screensaver)$"
        "noborder,   class:^(screensaver)$"

        "opacity ${toString config.stylix.opacity.applications} ${toString config.stylix.opacity.applications}, class:^(org.gnome.Nautilus)$"
        "opacity ${toString config.stylix.opacity.applications} ${toString config.stylix.opacity.applications}, class:^(Spotify)$"
        "opacity ${toString config.stylix.opacity.applications} ${toString config.stylix.opacity.applications}, class:^(Slack)$"

        "opacity 0.9 0.9, class:^(obsidian)$"
      ]
      ++ (floatingPopupRules "class:^(org.kde.partitionmanager)$")
      ++ (floatingPopupRules "class:^(localsend_app)$")
      ++ (floatingPopupRules "class:^(1Password)$")
      ++ (floatingPopupRules "class:^(bruno)$")
      ++ [ "suppressevent maximize fullscreen, class:^(bruno)$" ] # bruno persists maximized state in ~/.config/bruno/preferences.json
      ++ (floatingPopupRules "title:^(hyprmon)$")
      ++ [
        "float, title:^(webcam)$"
        "size 320 240, title:^(webcam)$"
        "move 100%-330 100%-250, title:^(webcam)$"
        "pin, title:^(webcam)$"
        "noborder, title:^(webcam)$"
      ];

      # standard key bindings with descriptions (bindd = bind with description)
      bindd = [
        "$mod, Return,       Terminal,              exec, ${terminalHere}"
        "$mod, Escape,       Power panel,           exec, $noctalia powerPanel toggle"
        "$mod SHIFT, Return, Browser,               exec, google-chrome-stable"
        "$mod, F,            Fullscreen,            fullscreen"
        "$mod SHIFT, F,      File manager,          exec, nautilus --new-window"
        "$mod, Q,            Close window,          killactive"

        "$mod, SPACE,        Launch apps,           exec, $noctalia launcher toggle"
        "$mod, B,            Toggle bar,            exec, $noctalia bar toggle"
        "$mod, J,            Toggle split,          togglesplit"
        "$mod, P,            Pseudo window,         pseudo"
        "$mod, O,            Pop window out,        exec, ${popWindow}"
        "$mod, T,            Control center,        exec, $noctalia sidePanel toggle"
        "$mod, slash,        Voice input,           exec, ${voiceInput}"
        "$mod, M,            Monitor settings,      exec, kitty --single-instance --instance-group popup --session none --title hyprmon -e hyprmon"

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

        # swap tiles
        "$mod SHIFT, left,  Swap window left,  swapwindow, l"
        "$mod SHIFT, right, Swap window right, swapwindow, r"
        "$mod SHIFT, up,    Swap window up,    swapwindow, u"
        "$mod SHIFT, down,  Swap window down,  swapwindow, d"

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
        ", XF86AudioMute,    Mute audio, exec, $noctalia audio muteOutput"
        ", XF86AudioMicMute, Mute mic,   exec, $noctalia audio muteInput"

        # screenshots — saves to ~/Pictures, copies to clipboard, click notification to edit
        "$mod, S,            Screenshot region,  exec, ${screenshot}"
      ];

      # repeatable bindings — fire continuously while key is held
      bindel = [
        ", XF86AudioRaiseVolume,  exec, $noctalia audio increase"
        ", XF86AudioLowerVolume,  exec, $noctalia audio decrease"
        ", XF86MonBrightnessUp,   exec, $noctalia brightness increase"
        ", XF86MonBrightnessDown, exec, $noctalia brightness decrease"
      ];

      # mouse bindings (held modifier + mouse button)
      bindm = [
        "$mod, mouse:272, movewindow"   # left click drag — move window
        "$mod, mouse:273, resizewindow" # right click drag — resize window
      ];
    };
  };
}
