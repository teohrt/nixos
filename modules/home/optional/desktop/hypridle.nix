{ pkgs, ... }:
let
  # Alacritty config used exclusively for the screensaver window — black bg, hidden cursor.
  alacrittyScreensaverConfig = pkgs.writeText "alacritty-screensaver.toml" ''
    [colors.primary]
    background = "0x000000"

    [colors.cursor]
    cursor = "0x000000"

    [font]
    size = 18.0

    [window]
    opacity = 1.0
  '';

  # Runs inside the screensaver terminal — loops tte with random effects.
  # Exits on any keypress or when the window loses focus.
  screensaverCmd = pkgs.writeShellScriptBin "screensaver-cmd" ''
    EFFECTS=(beams binarypath blackhole bouncyballs bubbles burn colorshift crumble
             decrypt errorcorrect expand fireworks highlight laseretch matrix middleout
             orbittingvolley overflow pour rain rings scattered slice slide spotlights
             spray swarm sweep synthgrid unstable vhstape waves wipe)

    screensaver_in_focus() {
      hyprctl activewindow -j | ${pkgs.jq}/bin/jq -e '.class == "screensaver"' >/dev/null 2>&1
    }

    exit_screensaver() {
      hyprctl keyword cursor:invisible false &>/dev/null || true
      pkill -x tte 2>/dev/null
      pkill -f "class=screensaver" 2>/dev/null
      exit 0
    }

    trap exit_screensaver SIGINT SIGTERM SIGHUP SIGQUIT

    printf '\033]11;rgb:00/00/00\007'
    hyprctl keyword cursor:invisible true &>/dev/null

    while true; do
      effect="''${EFFECTS[$((RANDOM % ''${#EFFECTS[@]}))]}"
      ${pkgs.terminaltexteffects}/bin/tte \
        --input-file ${../../../../assets/screensaver.txt} \
        --frame-rate 120 --canvas-width 0 --canvas-height 0 \
        --anchor-canvas c --anchor-text c \
        "$effect" &
      tte_pid=$!

      while kill -0 "$tte_pid" 2>/dev/null; do
        if read -n1 -t 1 || ! screensaver_in_focus; then
          exit_screensaver
        fi
      done
    done
  '';

  # Toggles the screensaver on/off via a state file and notifies the user.
  toggleScreensaver = pkgs.writeShellScriptBin "toggle-screensaver" ''
    STATE="$HOME/.local/state/screensaver-off"
    if [ -f "$STATE" ]; then
      rm "$STATE"
      notify-send "Screensaver" "Screensaver enabled"
    else
      mkdir -p "$(dirname "$STATE")"
      touch "$STATE"
      notify-send "Screensaver" "Screensaver disabled"
    fi
  '';

  # Launches the screensaver terminal on every connected monitor.
  # Exits silently if the screensaver has been toggled off.
  launchScreensaver = pkgs.writeShellScriptBin "launch-screensaver" ''
    [ -f "$HOME/.local/state/screensaver-off" ] && exit 0
    hyprctl clients -j | ${pkgs.jq}/bin/jq -e 'any(.[]; .class == "screensaver")' >/dev/null 2>&1 && exit 0

    walker -q 2>/dev/null || true

    focused=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.focused == true).name')

    for m in $(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | .name'); do
      hyprctl dispatch focusmonitor "$m"
      hyprctl dispatch exec -- alacritty \
        --class=screensaver \
        --config-file ${alacrittyScreensaverConfig} \
        -e screensaver-cmd
    done

    hyprctl dispatch focusmonitor "$focused"
  '';
in
{
  home.packages = [ screensaverCmd launchScreensaver toggleScreensaver ];

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd        = "hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd  = "sleep 1 && hyprctl dispatch dpms on";
        inhibit_sleep   = 3;
      };

      listener = [
        {
          timeout    = 150;  # 2.5 min — launch screensaver (skipped if already locked)
          on-timeout = "pidof hyprlock || ${launchScreensaver}/bin/launch-screensaver";
        }
        {
          timeout    = 151;  # immediately after screensaver — lock screen
          on-timeout = "loginctl lock-session";
        }
        {
          timeout    = 330;  # 5.5 min — keyboard backlight off
          on-timeout = "brightnessctl -sd '*::kbd_backlight' set 0";
          on-resume  = "brightnessctl -rd '*::kbd_backlight'";
        }
        {
          timeout    = 330;  # 5.5 min — screen off
          on-timeout = "hyprctl dispatch dpms off";
          on-resume  = "hyprctl dispatch dpms on && brightnessctl -r";
        }
        {
          timeout    = 600;  # 10 min — suspend
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
