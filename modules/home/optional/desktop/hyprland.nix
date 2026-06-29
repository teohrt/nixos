# Hyprland window manager configuration: thin Nix shim that generates context.lua
# with Stylix colors and Nix store paths, symlinks Lua config files, and packages
# helper shell scripts (screenshot, terminal-here, toggle-menu, voice-input).
{
  pkgs,
  config,
  pkgs-walker,
  pkgs-hyprland,
  ...
}:
let
  defaultScale = 1.25;

  # Lua data file generated at Nix build time.
  # Provides Stylix colors, Nix store binary paths, opacity settings, and
  # default scale to the hand-written Lua config files.
  contextLua = pkgs.writeText "context.lua" ''
    local M = {}

    -- Default monitor scale
    M.default_scale = ${toString defaultScale}

    -- Hostname (read at Lua runtime)
    do
      local f = io.open("/etc/hostname", "r")
      if f then
        M.hostname = f:read("*l"):match("^%s*(.-)%s*$")
        f:close()
      else
        M.hostname = "unknown"
      end
    end

    -- Stylix base16 colors
    M.colors = {
      base00 = "#${config.lib.stylix.colors.base00}",
      base01 = "#${config.lib.stylix.colors.base01}",
      base02 = "#${config.lib.stylix.colors.base02}",
      base03 = "#${config.lib.stylix.colors.base03}",
      base04 = "#${config.lib.stylix.colors.base04}",
      base05 = "#${config.lib.stylix.colors.base05}",
      base06 = "#${config.lib.stylix.colors.base06}",
      base07 = "#${config.lib.stylix.colors.base07}",
      base08 = "#${config.lib.stylix.colors.base08}",
      base09 = "#${config.lib.stylix.colors.base09}",
      base0A = "#${config.lib.stylix.colors.base0A}",
      base0B = "#${config.lib.stylix.colors.base0B}",
      base0C = "#${config.lib.stylix.colors.base0C}",
      base0D = "#${config.lib.stylix.colors.base0D}",
      base0E = "#${config.lib.stylix.colors.base0E}",
      base0F = "#${config.lib.stylix.colors.base0F}",
    }

    -- Stylix opacity settings
    M.opacity = {
      applications = ${toString config.stylix.opacity.applications},
      terminal = ${toString config.stylix.opacity.terminal},
    }

    -- Nix store binary paths
    M.bin = {
      socat = "${pkgs.socat}/bin/socat",
      jq = "${pkgs.jq}/bin/jq",
      slurp = "${pkgs.slurp}/bin/slurp",
      grim = "${pkgs.grim}/bin/grim",
      grimblast = "${pkgs.grimblast}/bin/grimblast",
      wl_copy = "${pkgs.wl-clipboard}/bin/wl-copy",
      notify_send = "${pkgs.libnotify}/bin/notify-send",
      satty = "${pkgs.satty}/bin/satty",
      brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl",
      mpv = "${pkgs.mpv}/bin/mpv",
      wf_recorder = "${pkgs.wf-recorder}/bin/wf-recorder",
      whisper_cli = "${pkgs.whisper-cpp}/bin/whisper-cli",
      wtype = "${pkgs.wtype}/bin/wtype",
      pw_record = "${pkgs.pipewire}/bin/pw-record",
      curl = "${pkgs.curl}/bin/curl",
      pgrep = "${pkgs.procps}/bin/pgrep",
      pkill = "${pkgs.procps}/bin/pkill",
      ps = "${pkgs.procps}/bin/ps",
      grep = "${pkgs.gnugrep}/bin/grep",
      walker = "${pkgs-walker.walker}/bin/walker",
      polkit_agent = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1",
    }

    return M
  '';

  # --- Shell scripts (writeShellScriptBin so they install as named commands) ---

  walker = "${pkgs-walker.walker}/bin/walker";

  # Opens kitty in the focused terminal's working directory (or home if not a terminal)
  # If workspace is empty, centers the terminal; otherwise tiles normally.
  terminal-here = pkgs.writeShellScriptBin "terminal-here" ''
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

  # Takes a screenshot, copies to clipboard, and shows notification.
  # Click notification to edit in Satty.
  screenshot = pkgs.writeShellScriptBin "screenshot" ''
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

  # Toggle menu - quick actions via walker dmenu
  # Screen option has 1s delay to avoid capturing the menu itself
  toggle-menu = pkgs.writeShellScriptBin "toggle-menu" ''
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
      ${pkgs.libnotify}/bin/notify-send -u low "Recording started"
    }

    set_brightness() {
      ${pkgs.brightnessctl}/bin/brightnessctl set "$1" -q
      current=$(${pkgs.brightnessctl}/bin/brightnessctl -m | cut -d, -f4)
      ${pkgs.libnotify}/bin/notify-send -u low -t 1000 "Brightness" "$current"
    }

    # Toggle webcam preview window for screen recordings with face cam
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

        choice=$(printf "$cameras" | ${walker} --dmenu -p "Camera")
        [[ -z "$choice" ]] && return

        # Extract device path from selection
        device=$(echo "$choice" | grep -oP '/dev/video\d+')

        ${pkgs.mpv}/bin/mpv --no-osc --geometry=320x240-10-10 --ontop --no-border \
          --title=webcam --profile=low-latency --untimed --no-cache \
          av://v4l2:"$device" &
      fi
    }

    if pgrep -x wf-recorder > /dev/null; then
      record_option="Stop Recording"
    else
      record_option="Record Screen"
    fi

    choice=$(printf "Take Screenshot\n$record_option\nWebcam Preview\nScreensaver\nBrightness\nVolume" | ${walker} --dmenu -p "Toggle")
    case "$choice" in
      "Take Screenshot")
        sub=$(printf "Region\nWindow\nScreen" | ${walker} --dmenu -p "Screenshot")
        case "$sub" in
          Region) take_screenshot region ;;
          Window) take_screenshot window ;;
          Screen) take_screenshot screen ;;
        esac
        ;;
      "Stop Recording")
        pkill -x wf-recorder
        file=$(cat /tmp/current-recording 2>/dev/null)
        rm -f /tmp/current-recording
        ${pkgs.libnotify}/bin/notify-send -u low "Recording saved" "$file"
        ;;
      "Record Screen")
        sub=$(printf "With Audio\nNo Audio" | ${walker} --dmenu -p "Record")
        case "$sub" in
          "With Audio") start_recording audio ;;
          "No Audio") start_recording ;;
        esac
        ;;
      "Webcam Preview")
        toggle_webcam
        ;;
      "Screensaver")
        launch-screensaver
        ;;
      "Brightness")
        current=$(${pkgs.brightnessctl}/bin/brightnessctl -m | cut -d, -f4)
        sub=$(printf "Minimum\n25%%\n50%%\n75%%\n100%%" | ${walker} --dmenu -p "Brightness ($current)")
        case "$sub" in
          Minimum) set_brightness 1 ;;
          25%) set_brightness 25% ;;
          50%) set_brightness 50% ;;
          75%) set_brightness 75% ;;
          100%) set_brightness 100% ;;
        esac
        ;;
      "Volume")
        current=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%.0f%%", $2 * 100}')
        sub=$(printf "0%%\n25%%\n50%%\n75%%\n100%%" | ${walker} --dmenu -p "Volume ($current)")
        case "$sub" in
          0%) wpctl set-volume @DEFAULT_AUDIO_SINK@ 0% ;;
          25%) wpctl set-volume @DEFAULT_AUDIO_SINK@ 25% ;;
          50%) wpctl set-volume @DEFAULT_AUDIO_SINK@ 50% ;;
          75%) wpctl set-volume @DEFAULT_AUDIO_SINK@ 75% ;;
          100%) wpctl set-volume @DEFAULT_AUDIO_SINK@ 100% ;;
        esac
        ;;
    esac
  '';

  # Voice-to-text using whisper-cpp
  # First press starts recording, second press stops and transcribes
  voice-input = pkgs.writeShellScriptBin "voice-input" ''
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
  home.packages = [
    pkgs.hyprmon
    pkgs.wf-recorder
    pkgs.whisper-cpp
    pkgs.wtype
    terminal-here
    screenshot
    toggle-menu
    voice-input
  ];

  systemd.user.tmpfiles.rules = [
    "d %h/Pictures/Screenshots 0755 - - -"
  ];

  # Symlink Lua config files into ~/.config/hypr/
  xdg.configFile = {
    "hypr/hyprland.lua".source = ./hyprland/init.lua;
    "hypr/settings.lua".source = ./hyprland/settings.lua;
    "hypr/monitors.lua".source = ./hyprland/monitors.lua;
    "hypr/rules.lua".source = ./hyprland/rules.lua;
    "hypr/binds.lua".source = ./hyprland/binds.lua;
    "hypr/autostart.lua".source = ./hyprland/autostart.lua;
    "hypr/events.lua".source = ./hyprland/events.lua;
    "hypr/context.lua".source = contextLua;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs-hyprland.hyprland;
    # Empty settings — Lua config takes priority via hyprland.lua
    settings = { };
  };
}
