# Hyprland window manager configuration: keybindings, window rules, animations,
# and helper scripts for screenshots, screen recording, voice input, etc.
{ pkgs, lib, config, ... }:
let
  # Outputs "width height" for half the focused monitor's dimensions (accounting for scale).
  # Used by multiple scripts for consistent centered window sizing.
  # Calculated dynamically rather than cached at login so it stays correct when
  # monitors are connected/disconnected or scaling changes mid-session.
  halfScreenSize = pkgs.writeShellScript "half-screen-size" ''
    hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[0] | "\(.width / .scale / 2 | floor) \(.height / .scale / 2 | floor)"'
  '';

  # Listens on Hyprland's IPC event socket and closes walker popup whenever the
  # active workspace changes. Needed because walker is a layer surface (not a
  # window) so it persists across workspace switches and ignores normal focus-loss
  # rules. Uses `walker --close` instead of pkill to preserve the background service.
  closeWalkerOnWorkspaceSwitch = pkgs.writeShellScript "close-walker-on-workspace-switch" ''
    socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
    ${pkgs.socat}/bin/socat -u "UNIX-CONNECT:$socket" - | while IFS= read -r line; do
      case "$line" in
        workspace\>\>*) walker --close || true ;;
      esac
    done
  '';

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

          # Skip waybar-spawned floating terminals (they have specific titles)
          case "$title" in
            hyprmon|wifi|bluetooth|audio|battery|webcam) continue ;;
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

  # Toggle waybar on/off - includes fix for waybar not appearing after monitor changes
  toggleWaybar = pkgs.writeShellScript "toggle-waybar" ''
    notify() {
      ${pkgs.libnotify}/bin/notify-send -u low -t 2000 "Waybar" "$1"
    }

    # Check if waybar has a visible layer surface
    waybar_visible() {
      hyprctl layers | grep -q "namespace: waybar"
    }

    # Reset internal display to fix layer-shell state
    reset_display() {
      internal=$(hyprctl monitors all -j | ${pkgs.jq}/bin/jq -r '.[] | select(.name | startswith("eDP")) | .name' | head -1)
      [[ -z "$internal" ]] && return 1
      hyprctl keyword monitor "$internal,disable"
      sleep 0.3
      hyprctl keyword monitor "$internal,preferred,auto,1.25"
    }

    # If waybar is running but not visible, reset display and restart waybar
    if systemctl --user is-active waybar &>/dev/null && ! waybar_visible; then
      reset_display
      sleep 0.3
      pkill -9 waybar 2>/dev/null
      sleep 0.3
      systemctl --user start waybar
      hyprctl reload  # fix duplicate cursor
      notify "Restored"
    elif systemctl --user is-active waybar &>/dev/null; then
      systemctl --user stop waybar
      notify "Stopped"
    else
      systemctl --user start waybar
      notify "Started"
    fi
  '';

  # Auto-mirror: when external monitor connects, make laptop (eDP-*) mirror it
  # External runs at native resolution, laptop shows scaled copy
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

      hyprctl keyword monitor "$internal,preferred,auto,1,mirror,$external"
    }

    handle_disconnect() {
      local internal=$(get_internal)
      [[ -z "$internal" ]] && return

      # Restore internal monitor config
      hyprctl keyword monitor "$internal,preferred,auto,1.25"

      # Restore wallpaper
      sleep 1
      ${pkgs.swww}/bin/swww restore 2>/dev/null || true
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
      read -r width height < <(${halfScreenSize})
      hyprctl dispatch togglefloating address:$addr
      hyprctl dispatch resizeactive exact $width $height
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
      read -r width height < <(${halfScreenSize})
      hyprctl --batch "dispatch togglefloating; dispatch resizeactive exact $width $height; dispatch centerwindow"
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
      # Pipeline explanation:
      #   whisper-cli: transcribe audio, -np disables progress output
      #   sed: strip timestamps like [00:00:00.000 --> 00:00:02.000] from line starts
      #   grep -v: remove blank lines between sentences
      #   tr: join all lines into one with spaces
      #   sed: normalize multiple spaces to single, trim leading/trailing
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

  # Toggle menu - quick actions via walker dmenu
  # Screen option has 1s delay to avoid capturing the menu itself
  toggleMenu = pkgs.writeShellScript "toggle-menu" ''
    take_screenshot() {
      file=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png

      case "$1" in
        region)
          # Select region first (cursor visible), then hide cursor and capture
          region=$(${pkgs.slurp}/bin/slurp) || return 1
          cursorpos=$(hyprctl cursorpos)
          hyprctl dispatch movecursor 99999 99999
          ${pkgs.grim}/bin/grim -g "$region" "$file"
          result=$?
          hyprctl dispatch movecursor ''${cursorpos// / }
          ${pkgs.wl-clipboard}/bin/wl-copy < "$file"
          ;;
        window|screen)
          # Hide cursor, capture, restore
          cursorpos=$(hyprctl cursorpos)
          hyprctl dispatch movecursor 99999 99999
          if [[ "$1" == "window" ]]; then
            ${pkgs.grimblast}/bin/grimblast copysave active "$file"
          else
            ${pkgs.grimblast}/bin/grimblast copysave screen "$file"
          fi
          result=$?
          hyprctl dispatch movecursor ''${cursorpos// / }
          ;;
      esac

      [[ $result -ne 0 ]] && return 1
      (
        action=$(${pkgs.libnotify}/bin/notify-send -u low -a "Screenshot" -i "$file" \
          "Screenshot saved" "Copied to clipboard. $file" \
          --action="default=Open" \
          --action="edit=Edit")
        case "$action" in
          default) xdg-open "$file" ;;
          edit) ${pkgs.satty}/bin/satty --filename "$file" ;;
        esac
      ) &
    }

    start_recording() {
      mkdir -p ~/Videos/Recordings
      file=~/Videos/Recordings/$(date +%Y-%m-%d_%H-%M-%S).mp4
      echo "$file" > /tmp/current-recording
      ${pkgs.libnotify}/bin/notify-send -u low -t 800 "Recording in 3..."
      sleep 1
      ${pkgs.libnotify}/bin/notify-send -u low -t 800 "Recording in 2..."
      sleep 1
      ${pkgs.libnotify}/bin/notify-send -u low -t 800 "Recording in 1..."
      sleep 1
      if [[ "$1" == "audio" ]]; then
        ${pkgs.wf-recorder}/bin/wf-recorder -a -f "$file" &
      else
        ${pkgs.wf-recorder}/bin/wf-recorder -f "$file" &
      fi
      pkill -RTMIN+8 waybar
      ${pkgs.libnotify}/bin/notify-send -u low "Recording started"
    }

    set_brightness() {
      ${pkgs.brightnessctl}/bin/brightnessctl set "$1" -q
      current=$(${pkgs.brightnessctl}/bin/brightnessctl -m | cut -d, -f4)
      ${pkgs.libnotify}/bin/notify-send -u low -t 1000 "Brightness" "$current"
    }

    # Toggle webcam preview window for screen recordings with face cam
    # Uses low-latency mpv settings to minimize delay
    # When webcam is on: turns it off. When off: shows camera selection menu.
    toggle_webcam() {
      if pgrep -f "mpv.*title=webcam" > /dev/null; then
        pkill -f "mpv.*title=webcam"
      else
        # Build camera list from sysfs - only include even-numbered devices (capture, not metadata)
        cameras=""
        for dev in /dev/video*; do
          num=$(basename "$dev" | tr -dc '0-9')
          if [[ $((num % 2)) -eq 0 ]]; then
            name=$(cat "/sys/class/video4linux/$(basename $dev)/name" 2>/dev/null | sed 's/:$//')
            [[ -n "$name" ]] && cameras+="$name ($dev)\n"
          fi
        done

        choice=$(printf "$cameras" | walker --dmenu -p "Camera")
        [[ -z "$choice" ]] && return

        # Extract device path from selection
        device=$(echo "$choice" | grep -oP '/dev/video\d+')

        ${pkgs.mpv}/bin/mpv --no-osc --geometry=320x240-10-10 --ontop --no-border \
          --title=webcam --profile=low-latency --untimed --no-cache \
          av://v4l2:"$device" &
      fi
    }

    choice=$(printf "Take Screenshot\nRecord Screen\nWebcam Preview\nAdjust Brightness" | walker --dmenu -p "Toggle")
    case "$choice" in
      "Take Screenshot")
        sub=$(printf "Region\nWindow\nScreen" | walker --dmenu -p "Screenshot")
        case "$sub" in
          Region) take_screenshot region ;;
          Window) take_screenshot window ;;
          Screen) take_screenshot screen ;;
        esac
        ;;
      "Record Screen")
        sub=$(printf "With Audio\nNo Audio" | walker --dmenu -p "Record")
        case "$sub" in
          "With Audio") start_recording audio ;;
          "No Audio") start_recording ;;
        esac
        ;;
      "Webcam Preview")
        toggle_webcam
        ;;
      "Adjust Brightness")
        current=$(${pkgs.brightnessctl}/bin/brightnessctl -m | cut -d, -f4)
        sub=$(printf "Minimum\n25%%\n50%%\n75%%\n100%%" | walker --dmenu -p "Brightness ($current)")
        case "$sub" in
          Minimum) set_brightness 1 ;;
          25%) set_brightness 25% ;;
          50%) set_brightness 50% ;;
          75%) set_brightness 75% ;;
          100%) set_brightness 100% ;;
        esac
        ;;
    esac
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
  home.packages = [ pkgs.hyprmon pkgs.wf-recorder pkgs.whisper-cpp pkgs.wtype ];

  systemd.user.tmpfiles.rules = [
    "d %h/Pictures/Screenshots 0755 - - -"
  ];

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      # use preferred resolution, auto-position, 1.2x scaling
      monitor = ",preferred,auto,1.2";

      "$terminal" = "kitty";
      "$menu" = "walker -N -H";
      "$mod" = "SUPER";

      exec-once = [
        "swayosd-server"                                   # OSD server for volume/brightness popups
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" # auth agent for privilege escalation prompts
        "${closeWalkerOnWorkspaceSwitch}"                  # close walker on workspace switch (layer surfaces ignore normal focus rules)
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
        "col.active_border" = lib.mkForce "rgba(ffffff2e)";
        "col.inactive_border" = lib.mkForce "rgba(ffffff2e)";
        layout = "dwindle"; # binary space partitioning layout
      };

      misc = {
        focus_on_activate = true; # switch to workspace when app requests focus
      };

      animations = {
        enabled = true;
        # smooth deceleration curve for all animations
        bezier = "easeOutQuart, 0.25, 1, 0.5, 1";
        animation = [
          "windows, 1, 0.75, easeOutQuart, slide"
          "windowsOut, 1, 0.75, easeOutQuart, slide"
          "fade, 1, 2, easeOutQuart"
          "workspaces, 1, 0.75, easeOutQuart, slide"
          "layers, 1, 2, easeOutQuart, popin 80%"
        ];
      };

      decoration = {
        rounding = 0;
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

        "opacity ${toString config.stylix.opacity.applications} ${toString config.stylix.opacity.applications}, class:^(org.gnome.Nautilus)$"
        "opacity ${toString config.stylix.opacity.applications} ${toString config.stylix.opacity.applications}, class:^(spotify)$"
        "opacity ${toString config.stylix.opacity.applications} ${toString config.stylix.opacity.applications}, class:^(Slack)$"
        "opacity 0.9 0.9, class:^(code)$"
        "opacity 0.9 0.9, class:^(obsidian)$"
        "float,      class:^(org.kde.partitionmanager)$"
        "size 650 450, class:^(org.kde.partitionmanager)$"
        "center,     class:^(org.kde.partitionmanager)$"
        "pin,        class:^(org.kde.partitionmanager)$"

        "float,      class:^(localsend_app)$"
        "size 650 450, class:^(localsend_app)$"
        "center,     class:^(localsend_app)$"
        "pin,        class:^(localsend_app)$"

        "float,      class:^(1password)$"
        "size 650 450, class:^(1password)$"
        "center,     class:^(1password)$"
        "pin,        class:^(1password)$"

        "float,      title:^(hyprmon)$"
        "size 900 600, title:^(hyprmon)$"
        "center,     title:^(hyprmon)$"
        "animation slide top, title:^(hyprmon)$"

        "float, title:^(wifi)$"
        "size 900 600, title:^(wifi)$"
        "center, title:^(wifi)$"
        "animation slide top, title:^(wifi)$"
        "float, title:^(bluetooth)$"
        "size 900 600, title:^(bluetooth)$"
        "center, title:^(bluetooth)$"
        "animation slide top, title:^(bluetooth)$"

        "float, title:^(webcam)$"
        "size 320 240, title:^(webcam)$"
        "move 100%-330 100%-250, title:^(webcam)$"
        "pin, title:^(webcam)$"
        "noborder, title:^(webcam)$"
        "float, title:^(audio)$"
        "size 900 600, title:^(audio)$"
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
        "$mod, Return,       Terminal,              exec, ${terminalHere}"
        "$mod, Escape,       Power menu,            exec, power-menu"
        "$mod SHIFT, Return, Browser,               exec, google-chrome-stable"
        "$mod, F,            Fullscreen,            fullscreen"
        "$mod SHIFT, F,      File manager,          exec, nautilus --new-window"
        "$mod, Q,            Close window,          killactive"

        "$mod, SPACE,        Launch apps,           exec, $menu"
        "$mod, B,            Toggle waybar,         exec, ${toggleWaybar}"
        "$mod, J,            Toggle split,          togglesplit"
        "$mod, P,            Pseudo window,         pseudo"
        "$mod, O,            Pop window out,        exec, ${popWindow}"
        "$mod, K,            Show keybindings,      exec, ${keybindingsMenu}"
        "$mod, T,            Toggle menu,           exec, ${toggleMenu}"
        "$mod, slash,        Voice input,           exec, ${voiceInput}"
        "$mod, M,            Monitor settings,      exec, kitty --title hyprmon -e hyprmon"

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
        ", XF86AudioMute,    Mute audio, exec, swayosd-client --output-volume mute-toggle"
        ", XF86AudioMicMute, Mute mic,   exec, swayosd-client --input-volume mute-toggle"

        # screenshots — saves to ~/Pictures, copies to clipboard, click notification to edit
        "$mod, S,            Screenshot region,  exec, ${screenshot}"
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
