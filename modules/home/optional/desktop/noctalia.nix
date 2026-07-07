# Noctalia v5: bar, launcher, notifications, lock screen, OSD.
# Replaces waybar, walker, swaync, hyprlock, swayosd, and swww/mpvpaper.
# Hypridle is kept separately for the custom tte screensaver.
{ lib, noctalia, ... }:
{
  imports = [ noctalia.homeModules.default ];

  programs.noctalia = {
    enable = true;

    settings = {
      audio.enable_overdrive = true;

      bar.main = {
        position = "bottom";
        scale = 1.3;
        widget_spacing = 19;
        radius = 0;
        margin_edge = 0;
        margin_ends = 0;
        start = [ "workspaces" ];
        center = [
          "battery"
          "clock"
          "notifications"
        ];
        end = [
          "network"
          "sysmon"
          "bluetooth"
          "volume"
          "control-center"
        ];
      };

      control_center = {
        sidebar = "none";
        sidebar_section = "none";
        calendar.show_events_card = false;
      };

      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Nord";
      };

      location.address = "New York, US";

      dock.enabled = false;
      desktop_widgets.enabled = true;
      lockscreen_widgets.enabled = false;

      shell = {
        ui_scale = 1.2;
        animation.speed = 1.6;
        panel = {
          control_center_placement = "floating";
          open_near_click_control_center = true;
        };
      };

      widget.clock = {
        format = "{:%-I:%M %p - %A}";
        anchor = true;
      };

      widget.workspaces = {
        focused_color = "outline";
        occupied_color = "on_tertiary";
        empty_color = "on_tertiary";
        scale = 1.3;
      };
    };
  };

  # Let Noctalia use its own theming; disable Stylix's hyprpaper target
  stylix.targets.hyprpaper.enable = lib.mkForce false;
}
