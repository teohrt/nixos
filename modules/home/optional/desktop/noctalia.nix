# Noctalia Shell: bar, launcher, notifications, lock screen, OSD.
# Replaces waybar, walker, swaync, hyprlock, swayosd, and swww/mpvpaper.
# Hypridle is kept separately for the custom tte screensaver.
{ lib, noctalia, ... }:
{
  imports = [ noctalia.homeModules.default ];

  programs.noctalia-shell = {
    enable = true;

    settings = {
      bar = {
        barType = "simple";
        position = "bottom";
        density = "comfortable";
        showCapsule = false;
        showOutline = false;
        widgetSpacing = 6;
        fontScale = 1.2;
        widgets = {
          left = [
            { id = "Workspace"; focusedColor = "none"; occupiedColor = "none"; emptyColor = "none"; pillSize = 0.8; fontWeight = "bold"; }
          ];
          center = [
            { id = "Battery"; }
            { id = "Clock"; formatHorizontal = "h:mm AP  ddd, MMM dd"; }
            { id = "NotificationHistory"; }
          ];
          right = [
            { id = "Network"; }
            { id = "SystemMonitor"; }
            { id = "Bluetooth"; }
            { id = "Volume"; }
            { id = "ControlCenter"; }
          ];
        };
      };

      general = {
        radiusRatio = 0;
        boxRadiusRatio = 0;
        iRadiusRatio = 0;
        screenRadiusRatio = 0;
        showChangelogOnStartup = false;
        telemetryEnabled = false;
      };

      colorSchemes = {
        useWallpaperColors = false;
        predefinedScheme = "Nord";
        darkMode = true;
      };

      dock.enabled = false;
      desktopWidgets.enabled = true;

      # Hypridle handles idle/lock/screensaver — disable Noctalia's built-in idle management
      idle.enabled = false;
    };
  };

  # Let Noctalia use its own theming; disable Stylix's noctalia-shell and hyprpaper targets
  stylix.targets.noctalia-shell.enable = false;
  stylix.targets.hyprpaper.enable = lib.mkForce false;
}
