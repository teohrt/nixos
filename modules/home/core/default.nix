{ pkgs, pkgs-walker, ... }:
let
  powerMenu = pkgs.writeShellScriptBin "power-menu" ''
    CHOICE=$(printf "Shutdown\nRestart\nLock\nSuspend\nScreensaver\nToggle Screensaver\nLog Out" \
      | ${pkgs-walker.walker}/bin/walker --dmenu -N -H)
    case "$CHOICE" in
      Shutdown)           systemctl poweroff ;;
      Restart)            systemctl reboot ;;
      Lock)               hyprlock ;;
      Suspend)            systemctl suspend ;;
      Screensaver)        launch-screensaver ;;
      "Toggle Screensaver") toggle-screensaver ;;
      "Log Out")          hyprctl dispatch exit ;;
    esac
  '';
in
{
  home.username = "trace";
  home.homeDirectory = "/home/trace";

  programs.btop.enable = true;
  services.swaync = {
    enable = true;
    settings = {
      border-radius = 10;
      width = 250;
      timeout = 0;
      timeout-low = 3;
      timeout-critical = 0;
    };
    style = ''
      .notification-content {
        padding: 1em;
      }

      .control-center {
        background-color: alpha(@window_bg_color, 0.7);
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

  home.packages = [ powerMenu ];

  home.stateVersion = "25.11";
}
