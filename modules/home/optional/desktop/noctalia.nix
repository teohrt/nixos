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
        showCapsule = true;
        showOutline = false;
        widgets = {
          left = [
            { id = "Workspace"; }
          ];
          center = [
            { id = "Battery"; }
            { id = "Clock"; }
            { id = "NotificationHistory"; }
          ];
          right = [
            { id = "Network"; }
            { id = "SystemMonitor"; }
            { id = "Bluetooth"; }
            { id = "Volume"; }
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

      dock.enabled = false;
      desktopWidgets.enabled = true;

      # Hypridle handles idle/lock/screensaver — disable Noctalia's built-in idle management
      idle.enabled = false;
    };
  };

  # Noctalia provides its own wallpaper management; disable Stylix's hyprpaper target
  stylix.targets.hyprpaper.enable = lib.mkForce false;
}
