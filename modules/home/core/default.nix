{ pkgs, pkgs-walker, ... }:
let
  walker = "${pkgs-walker.walker}/bin/walker";

  # Caffeine menu — disable sleep/lock for a set duration or indefinitely.
  # Uses systemd-inhibit to block idle; state file tracks active inhibit PID.
  caffeineMenu = pkgs.writeShellScriptBin "caffeine-menu" ''
    STATE="$HOME/.local/state/caffeine-pid"

    # Check if caffeine is currently active
    if [ -f "$STATE" ]; then
      pid=$(cat "$STATE")
      if kill -0 "$pid" 2>/dev/null; then
        CHOICE=$(printf "Turn Off Caffeine\n30 minutes\n1 hour\n2 hours\nIndefinitely" \
          | ${walker} --dmenu -N -H)
        if [ "$CHOICE" = "Turn Off Caffeine" ]; then
          kill "$pid" 2>/dev/null
          rm -f "$STATE"
          ${pkgs.libnotify}/bin/notify-send -u low "Caffeine" "Sleep timer restored"
          exit 0
        fi
      else
        rm -f "$STATE"
      fi
    fi

    [ -z "$CHOICE" ] && CHOICE=$(printf "30 minutes\n1 hour\n2 hours\nIndefinitely" \
      | ${walker} --dmenu -N -H)

    case "$CHOICE" in
      "30 minutes") duration=1800 ;;
      "1 hour")     duration=3600 ;;
      "2 hours")    duration=7200 ;;
      "Indefinitely") duration="" ;;
      *) exit 0 ;;
    esac

    # Kill any existing caffeine
    [ -f "$STATE" ] && kill "$(cat "$STATE")" 2>/dev/null

    mkdir -p "$(dirname "$STATE")"

    if [ -n "$duration" ]; then
      (systemd-inhibit --what=idle --who=Caffeine --why="User requested" \
        sleep "$duration" && rm -f "$STATE" && \
        ${pkgs.libnotify}/bin/notify-send -u low "Caffeine" "Sleep timer restored") &
      echo $! > "$STATE"
      ${pkgs.libnotify}/bin/notify-send -u low "Caffeine" "Staying awake for $CHOICE"
    else
      (systemd-inhibit --what=idle --who=Caffeine --why="User requested" \
        sleep infinity) &
      echo $! > "$STATE"
      ${pkgs.libnotify}/bin/notify-send -u low "Caffeine" "Staying awake indefinitely"
    fi
  '';

  powerMenu = pkgs.writeShellScriptBin "power-menu" ''
    CHOICE=$(printf "Shutdown\nRestart\nLock\nSuspend\nScreensaver\nToggle Screensaver\nCaffeine\nLog Out" \
      | ${walker} --dmenu -N -H)
    case "$CHOICE" in
      Shutdown)           systemctl poweroff ;;
      Restart)            systemctl reboot ;;
      Lock)               hyprlock ;;
      Suspend)            systemctl suspend ;;
      Screensaver)        launch-screensaver ;;
      "Toggle Screensaver") toggle-screensaver ;;
      Caffeine)           caffeine-menu ;;
      "Log Out")          hyprctl dispatch exit ;;
    esac
  '';
in
{
  home.username = "trace";
  home.homeDirectory = "/home/trace";

  programs.btop.enable = true;
  # Disabled - .zshrc managed via dotfiles repo stow
  programs.zsh.enable = false;
  services.swaync = {
    enable = true;
    settings = {
      border-radius = 10;
      width = 250;
      timeout = 0;
      timeout-low = 3;
      timeout-critical = 0;
      fit-to-screen = false;
      control-center-height = 900;
      control-center-positionX = "center";
      control-center-positionY = "center";
    };
    style = ''
      .notification-content {
        padding: 1em;
      }

      .control-center {
        background-color: alpha(@window_bg_color, 0.7);
      }

      /* Hide broken placeholder image when no notifications */
      .control-center-list-placeholder image {
        opacity: 0;
        min-height: 0;
        min-width: 0;
      }
    '';
  };

  # Darken Nautilus background so text stays readable across light and dark themes.
  # shade() is a GTK CSS function: values < 1 darken, > 1 lighten.
  stylix.targets.gtk.extraCss = ''
    .nautilus-window {
      background-color: shade(@window_bg_color, 0.75);
    }
  '';

  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
    };
  };

  home.packages = [ powerMenu caffeineMenu ];

  home.stateVersion = "25.11";
}
