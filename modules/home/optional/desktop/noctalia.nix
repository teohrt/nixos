# Noctalia Shell: bar, launcher, notifications, lock screen, OSD.
# Replaces waybar, walker, swaync, hyprlock, swayosd, and swww/mpvpaper.
# Hypridle is kept separately for the custom tte screensaver.
{ lib, noctalia, ... }:
{
  imports = [ noctalia.homeModules.default ];

  programs.noctalia-shell = {
    enable = true;
    systemd.enable = true;

    settings = {
      bar = {
        position = "bottom";
        style = "compact";
        borderRadius = 0;
        widgets = {
          left = [ "workspaces" ];
          center = [ "battery" "clock" "notifications" ];
          right = [ "network" "temperature" "cpu" "memory" "bluetooth" "audio" ];
        };
      };

      dock.enable = false;
      desktop.enable = false;

      # Hypridle handles idle/lock/screensaver — disable Noctalia's built-in idle management
      idle.enable = false;
    };
  };

  # Noctalia provides its own wallpaper management; disable Stylix's hyprpaper target
  stylix.targets.hyprpaper.enable = lib.mkForce false;
}
